package Sub::Private;

# Minimum Perl version: 5.14 (${^GLOBAL_PHASE}, needed to protect subs in
# packages loaded after CHECK)
use 5.014;
use strict;
use warnings;

use Attribute::Handlers;
use B::Hooks::EndOfScope qw();
use Carp              qw(croak carp);
use Readonly;
use Params::Validate::Strict 0.33 qw(validate_strict);
use Return::Set       qw(set_return);
use Sub::Identify     qw(get_code_info);

# namespace::clean is used as a class method only; import nothing.
use namespace::clean qw();

=head1 NAME

Sub::Private - Private subroutines and methods

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

# ---------------------------------------------------------------------------
# Mode-name constants.  Using Readonly prevents accidental overwriting.
# ---------------------------------------------------------------------------

Readonly::Scalar my $MODE_NAMESPACE => 'namespace';
Readonly::Scalar my $MODE_ENFORCE   => 'enforce';

# Config-key constants -- avoids bare magic strings in %config lookups.
Readonly::Scalar my $KEY_MODE           => 'mode';
Readonly::Scalar my $KEY_HARNESS_BYPASS => 'harness_bypass';

# Self-referential constant: the canonical name of this package.
Readonly::Scalar my $SELF => __PACKAGE__;

# Validation schema for a single Perl sub name passed to import().
Readonly::Scalar my $SUB_NAME_SCHEMA => {
	name => {
		type  => 'string',
		regex => qr/\A[_a-zA-Z]\w*\z/,
	}
};

=head1 SYNOPSIS

    package Foo;
    use Sub::Private;

    sub foo { return 42 }

    sub bar :Private {
        return foo() + 1;
    }

    sub baz {
        return bar() + 1;
    }

=head1 DESCRIPTION

Enforces strictly private access on subroutines.  A subroutine decorated
with C<:Private> (or named in C<use Sub::Private qw(...)> when in enforce
mode) may only be called from within its defining package.  Subclasses do
not inherit access: private means I<this package only>.

=head2 Two enforcement modes

=over 4

=item C<namespace> mode (default, backward-compatible)

Removes the subroutine from the package symbol table using
L<namespace::clean>.  Direct (non-method) function calls compiled before
cleanup still work because Perl optimises them to direct opcode references.
OO method dispatch (C<$self->name>) does not work for private subs in this
mode because method lookup uses the symbol table at runtime.

This is the default mode and is backward-compatible with all existing code.

=item C<enforce> mode (OO-safe, opt-in)

Replaces the subroutine with a wrapper closure that checks C<caller> at
call time and either delegates (owner package) or croaks (anyone else).
Works correctly with OO dispatch (C<$self->_helper>).

Enable before declaring your first private sub:

    BEGIN { $Sub::Private::config{mode} = 'enforce' }
    package MyClass;
    use Sub::Private;
    sub _helper :Private { ... }

=back

=head2 Behaviour of wrapped subs (enforce mode)

=over 4

=item * The wrapper hands over with C<goto &sub>, so it does not appear
on the call stack: C<caller> inside a private sub sees its real caller.

=item * Arguments, C<@_> aliasing and calling context (list, scalar or
void) are passed through unchanged.

=item * C<$_> is left untouched, whether the call is allowed or blocked.

=item * A blocked call croaks; it does not fall through to C<AUTOLOAD>.

=item * Works with L<Moo> and L<Moose> classes; use the declarative form
after C<use Moo> or C<use Moose>.

=back

=head2 Loading at run time

Packages that use C<Sub::Private> may be loaded at run time (C<require>,
a plugin loader, a string C<eval>), and C<Sub::Private> itself may be
loaded for the first time that way.  The private subs are then wrapped
(or removed, in C<namespace> mode) when the enclosing scope, normally the
rest of the file, has been compiled.

=head2 Bypass for testing

Either condition alone (OR logic) disables all access checks in enforce
mode:

=over 4

=item * C<$Sub::Private::BYPASS> set to a true value.  Use C<local> in
tests.

=item * C<$ENV{HARNESS_ACTIVE}> set (the convention used by
L<Test::Harness>/prove).

=back

C<$Sub::Private::BYPASS> is the recommended form for new test code.
The C<HARNESS_ACTIVE> bypass can be disabled:

    $Sub::Private::config{harness_bypass} = 0;

=head2 Configuration

    $Sub::Private::config{mode}            -- 'namespace' (default) or 'enforce'
    $Sub::Private::config{harness_bypass}  -- 1 (default); set to 0 to test enforcement

=head2 Error message format (enforce mode)

    bar() is a private subroutine of Foo and cannot be called from Bar

=cut

# Public bypass flag.  Use C<local $Sub::Private::BYPASS = 1> in test code.
our $BYPASS = 0;

# Module configuration.  //= preserves any value a caller set in a BEGIN
# block before this module body runs.
our %config;
$config{$KEY_MODE}           //= $MODE_NAMESPACE;
$config{$KEY_HARNESS_BYPASS} //= 1;

# Pending (owner_pkg, sub_name) pairs to be wrapped at CHECK time.
# Populated by import(); consumed and cleared by the CHECK block.
my @_pending;

# True once CHECK has run, so wrapping must happen without it.  Set by our
# own CHECK block, or here when this module is first loaded after CHECK
# (run-time require, plugin loader, string eval).
my $_post_check = (${^GLOBAL_PHASE} ne 'START') ? 1 : 0;

# -------------------------------------------------------------------
# ATTRIBUTE HANDLER
# -------------------------------------------------------------------

# Install :Private in UNIVERSAL so every package can use it after a
# single "use Sub::Private", with no per-package setup required.
# ATTR(CODE,CHECK) fires at CHECK time, after all subs are compiled.
# The BEGIN phase covers code compiled after CHECK, when the CHECK-phase
# call never comes.
sub UNIVERSAL::Private :ATTR(CODE,BEGIN,CHECK) {
	my ($package, $symbol, $referent, $attr, $data, $phase) = @_;

	if ($phase eq 'BEGIN') {
		# Before CHECK, the CHECK-phase call does the work.
		return unless $_post_check;

		# After CHECK the sub is still being compiled and may have no name
		# yet, so finish the job when the enclosing scope is compiled.
		# on_scope_end works here because the user's code is compiling.
		B::Hooks::EndOfScope::on_scope_end(sub {
			my ($pkg, $name) = get_code_info($referent);
			no strict 'refs';	## no critic (ProhibitNoStrict)
			UNIVERSAL::Private($pkg, \*{"${pkg}::$name"}, $referent, $attr, $data, 'CHECK');
		});
		return;
	}

	my $sub_name = *{$symbol}{NAME};

	# Reject unrecognised mode values early rather than silently misbehaving.
	_assert_known_mode($config{$KEY_MODE});

	if ($config{$KEY_MODE} eq $MODE_ENFORCE) {
		# Enforce mode: replace the stash entry with an access-checking wrapper.
		no warnings 'redefine';
		*{$symbol} = _wrap($package, $sub_name, $referent);
	} else {
		# Namespace mode: remove the sub from the stash entirely.
		# on_scope_end does NOT work from a CHECK-phase callback, so we call
		# clean_subroutines() directly here.
		namespace::clean->clean_subroutines( get_code_info($referent) );
	}
	return;
}

# -------------------------------------------------------------------
# PUBLIC INTERFACE
# -------------------------------------------------------------------

=head1 PUBLIC INTERFACE

=head2 import

    use Sub::Private;                    # attribute form -- no arguments
    use Sub::Private qw(_a _b _c);      # declarative form (enforce mode only)

=head3 Purpose

Called automatically by C<use Sub::Private>.

With B<no arguments>: makes the C<:Private> attribute globally available
via C<UNIVERSAL>.  No other action is taken.

With B<one or more sub names>: registers those named subs in the calling
package for access-enforcement wrapping at C<CHECK> time.  If C<CHECK>
has already fired (for example the package is loaded with C<require> at
run time), the subs are wrapped as soon as the enclosing scope (normally
the rest of the file) has been compiled, so the C<use> line can still
come before the subs it names.  A direct C<< Sub::Private->import(...) >>
call at run time wraps immediately.  Requires C<$Sub::Private::config{mode}> to equal
C<'enforce'>; croaks otherwise.

=head3 Arguments

=over 4

=item C<@subs> (optional)

Zero or more Perl sub names.  Each must be a defined, non-reference scalar
matching C</\A[_a-zA-Z]\w*\z/>.  C<undef>, references, empty strings, and
names starting with a digit or containing hyphens are all rejected.

=back

=head3 Returns

The class name (C<'Sub::Private'>) as a plain string in all cases.

=head3 Side effects

=over 4

=item * Pre-CHECK: appends C<[$owner_pkg, $sub_name]> pairs to the
internal C<@_pending> list.

=item * Post-CHECK, during compilation: installs wrapper closures in the
calling package's stash when the enclosing scope has been compiled.

=item * Post-CHECK, at run time: installs wrapper closures directly in the
calling package's stash.

=back

=head3 Example

    BEGIN { $Sub::Private::config{mode} = 'enforce' }
    package MyClass;
    use Sub::Private qw(_helper _init);

    sub new     { bless {}, shift }
    sub _helper { ... }    # wrapped at CHECK time
    sub _init   { ... }    # wrapped at CHECK time
    sub run     { my $s = shift; $s->_helper; $s->_init }

=head3 API SPECIFICATION

=head4 Input

    # No-argument form: always valid.
    Sub::Private->import();

    # Declarative form (enforce mode only):
    {
        subs => {
            type     => 'array',
            optional => 1,
            element  => {
                type  => 'string',
                regex => qr/\A[_a-zA-Z]\w*\z/,
            },
        }
    }

=head4 Output

    { type => 'string' }    # returns the class name 'Sub::Private'

=head3 MESSAGES

    Message                                              Meaning / Action
    ---------------------------------------------------  -----------------------------------------------
    "Sub::Private->import: declarative form requires     use Sub::Private qw(...) was called while
     mode => 'enforce'"                                  $config{mode} is not 'enforce'.  Set
                                                         $config{mode} = 'enforce' in a BEGIN block
                                                         before "use Sub::Private".

    "Sub::Private->import: 'NAME' is not a valid         The sub name failed the identifier regex.
     Perl identifier"                                    Check for typos, hyphens, leading digits,
                                                         undef, or reference values in the import list.

    "Sub::Private: PKG::NAME is not defined"             The named sub was not found in the stash at
                                                         wrap time.  Define the sub before import()
                                                         runs, before CHECK fires, or (after CHECK)
                                                         before the end of the enclosing scope.
                                                         After CHECK, the location reported is the
                                                         "use Sub::Private" line.

=cut

sub import {
	my ($class, @subs) = @_;

	# No sub names: the :Private attribute is always available via UNIVERSAL.
	return set_return($class, { type => 'string' }) unless @subs;

	# Declarative form is only meaningful in enforce mode.
	croak "$SELF->import: declarative form requires mode => '$MODE_ENFORCE'"
		if $config{$KEY_MODE} ne $MODE_ENFORCE;

	# Validate every name before touching the stash (fail-fast, all-or-nothing).
	for my $sub_name (@subs) {
		# Coerce invalid types (undef, ref) to empty string before schema check.
		my $check = (defined $sub_name && !ref $sub_name) ? $sub_name : q{};
		eval {
			validate_strict(
				schema => $SUB_NAME_SCHEMA,
				input  => { name => $check },
			);
		};
		croak "$SELF->import: '$check' is not a valid Perl identifier" if $@;
	}

	# Schedule or immediately apply wrapping depending on compile phase.
	my ($owner_pkg, $file, $line) = caller;
	if ($_post_check) {
		if (defined $^S) {
			# Called at run time: the subs already exist, wrap them now.
			_process_one($owner_pkg, $_) for @subs;
		} else {
			# "use" after CHECK (e.g. a run-time require): the subs below the
			# "use" line are not compiled yet, so wrap them when the
			# enclosing scope has been compiled.
			B::Hooks::EndOfScope::on_scope_end(sub {
				# Report errors at the "use" line, not inside the hook.
				eval { _process_one($owner_pkg, $_) for @subs; 1 } or do {
					(my $err = $@) =~ s/ at .+? line \d+\.?\n\z//s;
					die "$err at $file line $line.\n";
				};
			});
		}
	} else {
		push @_pending, [ $owner_pkg, $_ ] for @subs;
	}

	return set_return($class, { type => 'string' });
}

# -------------------------------------------------------------------
# CHECK-TIME PROCESSING
# -------------------------------------------------------------------

# Process all declarative wraps queued during import().
# After this fires, $_post_check=1 so future import() calls wrap without it.
# When this module is loaded after CHECK the block cannot run, which is
# expected; silence "Too late to run CHECK block".
{
	no warnings 'void';
	CHECK {
		$_post_check = 1;
		_process_one(@$_) for @_pending;
		@_pending = ();
	}
}

# -------------------------------------------------------------------
# PRIVATE SUBROUTINES
# -------------------------------------------------------------------

# _assert_known_mode
# Purpose      : Validate that $config{mode} is a recognised string.
# Entry        : $mode -- the value to validate
# Exit status  : Returns normally for 'namespace' or 'enforce'; croaks
#                with a descriptive message for any other value.
sub _assert_known_mode {
	my ($mode) = @_;
	return if $mode eq $MODE_NAMESPACE || $mode eq $MODE_ENFORCE;
	croak "$SELF: unknown mode '$mode'"
		. " -- use '$MODE_NAMESPACE' or '$MODE_ENFORCE'";
}

# _process_one
# Purpose      : Look up a named sub in a package stash and install a wrapper.
# Entry        : $owner_pkg -- the package that declared the sub
#                $sub_name  -- the unqualified sub name to wrap
# Exit status  : Returns normally; the stash entry is replaced with a wrapper.
# Side effects : Modifies the package stash for $owner_pkg.
# Notes        : Guarded by _assert_private_caller -- external calls croak.
sub _process_one {
	my ($owner_pkg, $sub_name) = @_;

	# Guard: only Sub::Private itself may call this.
	_assert_private_caller('_process_one')
		unless $BYPASS || ($config{$KEY_HARNESS_BYPASS} && $ENV{HARNESS_ACTIVE});

	no strict 'refs';	## no critic (ProhibitNoStrict)

	# Ensure the target sub exists in the stash before wrapping.
	croak "$SELF: ${owner_pkg}::${sub_name} is not defined"
		unless defined &{"${owner_pkg}::${sub_name}"};

	my $code = \&{"${owner_pkg}::${sub_name}"};

	# Replace the stash entry with the enforcement wrapper.
	no warnings 'redefine';
	*{"${owner_pkg}::${sub_name}"} = _wrap($owner_pkg, $sub_name, $code);
	return;
}

# _wrap
# Purpose      : Build an enforcement wrapper closure around a coderef.
# Entry        : $owner_pkg -- the package that owns the private sub
#                $sub_name  -- the unqualified sub name (for error messages)
#                $code      -- the original coderef to delegate to
# Exit status  : Returns a new coderef that enforces the private-access rule.
# Side effects : none (variables captured by closure)
# Notes        : goto &$code is used rather than $code->(@_) so that caller()
#                inside the private sub sees the real caller, not Sub::Private.
#                This is load-bearing: removing it breaks tests that inspect
#                caller() inside a private sub.  Guarded by _assert_private_caller.
sub _wrap {
	my ($owner_pkg, $sub_name, $code) = @_;

	# Guard: only Sub::Private itself may call this.
	_assert_private_caller('_wrap')
		unless $BYPASS || ($config{$KEY_HARNESS_BYPASS} && $ENV{HARNESS_ACTIVE});

	# Capture the three args in the closure; the wrapper has no mutable state.
	return sub {
		Sub::Private::_check_access($owner_pkg, $sub_name);
		goto &$code;    ## no critic (ControlStructures::ProhibitGoto)
	};
}

# _check_access
# Purpose      : Enforce the private-access invariant at call time.
# Entry        : $owner_pkg -- the package that owns the private sub
#                $sub_name  -- unqualified sub name (for error messages)
# Exit status  : Returns normally if the immediate non-Sub::Private caller is
#                the owner package.  Croaks if any other package is found first.
# Notes        : Unlike Sub::Protected there is NO ->isa check.  Private means
#                the owner package ONLY; subclasses are blocked.
#                The stack walk skips Sub::Private frames so the wrapper is
#                transparent to the check.
sub _check_access {
	my ($owner_pkg, $sub_name) = @_;

	# Fast bypass paths: either condition alone disables all checks (OR logic).
	return if $BYPASS;
	return if $config{$KEY_HARNESS_BYPASS} && $ENV{HARNESS_ACTIVE};

	# Walk the call stack, skipping Sub::Private wrapper frames.
	my $frame = 0;
	while (1) {
		my $pkg = (caller($frame))[0];

		# Reached the bottom of the stack with no valid caller found.
		if (!defined $pkg) {
			croak "${sub_name}() is a private subroutine of ${owner_pkg}"
				. ' and cannot be called from outside any package';
		}

		# Skip any Sub::Private frames (e.g., the wrapper closure itself).
		$frame++, next if $pkg eq $SELF;

		# The first non-Sub::Private caller must be the owner; everyone else
		# is blocked -- no isa allowance, unlike Sub::Protected.
		return if $pkg eq $owner_pkg;
		croak "${sub_name}() is a private subroutine of ${owner_pkg}"
			. " and cannot be called from ${pkg}";
	}
}

# _assert_private_caller
# Purpose      : Croak if a guarded private method was called from outside
#                Sub::Private.
# Entry        : $method_name -- the guarded method name (for error messages)
# Exit status  : Returns normally if caller(1) is Sub::Private; croaks
#                otherwise with a descriptive message.
# Notes        : caller(1) is the package that called the guarded method,
#                which in turn called this function.
sub _assert_private_caller {
	my ($method_name) = @_;

	# caller(1): the package one frame above the guarded method.
	my $caller = (caller(1))[0] // q{};

	# Only calls originating within Sub::Private itself are permitted.
	return if $caller eq $SELF;

	croak "${method_name}() is a private method of $SELF"
		. " and cannot be called from ${caller}";
}

1;

__END__

=head1 PUBLIC VARIABLES

=head2 C<$BYPASS>

Set to a true value to disable all access checks (enforce mode only).
Use C<local> in tests; see L</Bypass for testing>.

=head2 C<%config>

Module-level configuration hash.  Supported keys:

=over 4

=item C<mode>

C<'namespace'> (default) or C<'enforce'>.  Must be set in a C<BEGIN>
block before C<use Sub::Private> to take effect at C<CHECK> time.

=item C<harness_bypass>

When true (default), access checks are skipped whenever
C<$ENV{HARNESS_ACTIVE}> is set.  Set to 0 to test enforcement under
C<prove>.

=back

=head1 KNOWN LIMITATIONS

=over 4

=item C<namespace> mode: OO dispatch fails for private subs

C<$self->_helper> from within the owner package fails because method
dispatch uses the symbol table at runtime, which no longer contains the
entry.  Use C<enforce> mode for OO classes.

=item C<enforce> mode: runtime-only

Checks are runtime only; there is no compile-time enforcement.

=item C<enforce> mode: raw coderef bypass

A raw code reference obtained B<before> wrapping (via C<can()> or
C<\&Foo::_helper>) bypasses the check.  The attribute form makes this
hard because wrapping happens at CHECK time.  When the package is loaded
after CHECK, wrapping happens at the end of the enclosing scope, so a
C<BEGIN> block earlier in the same file could still take a reference to
the unwrapped sub.

=item C<enforce> mode: C<can()> leaks private method existence

In C<enforce> mode the original sub is replaced by a wrapper closure, so
C<< ->can('_helper') >> returns the wrapper (a true value) even to callers outside
the owner package.  In C<namespace> mode the stash entry is deleted entirely,
so C<< ->can >> correctly returns C<undef>.  A future release may inject a
caller-aware C<can()> override into each class that uses C<enforce> mode,
returning the coderef only when the caller is the owner package and C<undef>
for everyone else.

=item UNIVERSAL namespace pollution

The C<:Private> attribute is installed in C<UNIVERSAL>, which is
intentional (any package can use it after a single C<use>), but it does
introduce C<UNIVERSAL::Private> into the global namespace.

=back

=head1 DEPENDENCIES

Perl 5.14 or later,
L<Carp> (core),
L<Attribute::Handlers> (core),
L<B::Hooks::EndOfScope>,
L<Readonly>,
L<Params::Validate::Strict>,
L<Return::Set>,
L<namespace::clean>,
L<Sub::Identify>.

=head1 SEE ALSO

=over 4

=item * L<Test Dashboard|https://nigelhorne.github.io/Sub-Private/coverage/>

=item * L<Sub::Protected>

Sister module enforcing protected (owner + subclass) rather than strictly private access

=item * L<Sub::Abstract>

Sister module enforcing abstract (virtual) methods

=item * L<namespace::clean>

=back

=head1 FORMAL SPECIFICATION

The following Z-notation schemas formally specify the C<CheckAccess>
operation and C<import>.

=head2 C<CheckAccess>

    -- Type abbreviations
    Package  == seq CHAR     -- a non-empty Perl package name string
    SubName  == seq CHAR     -- a Perl identifier string

    -- Private-access predicate (strictly owner only -- no isa expansion)
    permitted : Package x Package -> BOOL
    forall caller, owner : Package .
        permitted(caller, owner) <=> caller = owner

    -- System state
    +-Registry-------------------------------------------+
    | private   : P (Package x SubName)                  |
    | bypass    : BOOL                                    |
    | config    : { mode : seq CHAR,                      |
    |               harness_bypass : BOOL }               |
    +----------------------------------------------------+

    -- Initial state
    +-InitRegistry---------------------------------------+
    | Registry                                           |
    |----------------------------------------------------|
    | private   = {}                                     |
    | bypass    = false                                  |
    | config    = { mode |-> 'namespace',                 |
    |               harness_bypass |-> true }             |
    +----------------------------------------------------+

    -- Bypass predicate
    bypass_active(R) <=>
        R.bypass or (R.config.harness_bypass and HARNESS_ACTIVE)

    -- Access check: no state change
    +-CheckAccess----------------------------------------+
    | Xi-Registry                                        |
    | caller? : Package                                  |
    | owner?  : Package                                  |
    | name?   : SubName                                  |
    | ok!     : BOOL                                     |
    |----------------------------------------------------|
    | (owner?, name?) in private                         |
    | ok! <=> bypass_active or permitted(caller?, owner?)|
    +----------------------------------------------------+

    -- Violation (croak case):
    --   not ok! =>
    --   croak("name?()" ++ " is a private subroutine of " ++ owner?
    --         ++ " and cannot be called from " ++ caller?)

    -- Key difference from Sub::Protected:
    --   permitted(caller, owner) <=> caller = owner   (identity only)
    -- vs Sub::Protected:
    --   permitted(caller, owner) <=> owner in anc(caller)   (ISA chain)

=head2 import

    -- Valid identifier predicate
    valid_id : SubName -> BOOL
    valid_id(n) <=> n =~ /\A[_a-zA-Z]\w*\z/

    -- Compile phase: CHECK has run, and code is still being compiled
    post_check  : BOOL
    compiling   : BOOL       -- true while $^S is undefined

    -- Pre-condition (declarative form)
    +-ImportPre-----------------------------------------+
    | config.mode = 'enforce'                           |
    | forall n in subs . valid_id(n)                    |
    +---------------------------------------------------+

    -- Post-condition (before CHECK): queue for the CHECK block
    +-ImportPost_PreCheck-------------------------------+
    | not post_check                                    |
    |---------------------------------------------------|
    | pending' = pending ++ < (caller, n) | n in subs > |
    +---------------------------------------------------+

    -- Post-condition (after CHECK, at run time): wrap now
    +-ImportPost_RunTime--------------------------------+
    | post_check and not compiling                      |
    | forall n in subs . defined(caller, n)             |
    |---------------------------------------------------|
    | forall n in subs .                                |
    |   stash'(caller, n) = wrapper(caller, n)          |
    +---------------------------------------------------+

    -- Post-condition (after CHECK, while compiling): wrap at the
    -- end of the enclosing scope S
    +-ImportPost_Deferred-------------------------------+
    | post_check and compiling                          |
    |---------------------------------------------------|
    | at end_of_scope(S) :                              |
    |   (forall n in subs . defined(caller, n)) =>      |
    |     forall n in subs .                            |
    |       stash'(caller, n) = wrapper(caller, n)      |
    |   (exists n in subs . not defined(caller, n)) =>  |
    |     croak at the "use" line                       |
    +---------------------------------------------------+

    -- In every case, a sub that is not defined when wrapping is
    -- attempted croaks:
    --   "Sub::Private: " ++ caller ++ "::" ++ n ++ " is not defined"

=head1 AUTHOR

Original Author:
Peter Makholm, C<< <peter at makholm.net> >>

Current maintainer:
Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sub-private at rt.cpan.org>,
or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sub-Private>.

=head1 SUPPORT

    perldoc Sub::Private

=over 4

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sub-Private>

=item * MetaCPAN

L<https://metacpan.org/dist/Sub-Private>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Peter Makholm, all rights reserved.
Portions copyright 2024-2026 Nigel Horne.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
