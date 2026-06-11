package Sub::Private;

# Minimum Perl version: 5.8 (Attribute::Handlers became core in 5.8)
use 5.008;
use strict;
use warnings;
use autodie qw(:all);

use Attribute::Handlers;
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

Version 0.05

=cut

our $VERSION = '0.05';

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

# Set to 1 once the CHECK block fires so import() can wrap immediately.
my $_post_check = 0;

# -------------------------------------------------------------------
# ATTRIBUTE HANDLER
# -------------------------------------------------------------------

# Install :Private in UNIVERSAL so every package can use it after a
# single "use Sub::Private", with no per-package setup required.
# ATTR(CODE,CHECK) fires at CHECK time, after all subs are compiled.
sub UNIVERSAL::Private :ATTR(CODE,CHECK) {
	my ($package, $symbol, $referent, $attr, $data) = @_;
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
has already fired (e.g., when calling from a test), wrapping is applied
immediately.  Requires C<$Sub::Private::config{mode}> to equal
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

=item * Post-CHECK: installs wrapper closures directly in the calling
package's stash.

=back

=head3 Example

    BEGIN { $Sub::Private::config{mode} = 'enforce' }
    package MyClass;
    use Sub::Private qw(_helper _init);

    sub new     { bless {}, shift }
    sub _helper { ... }    # wrapped at CHECK time
    sub _init   { ... }    # wrapped at CHECK time
    sub run     { my $s = shift; $s->_helper; $s->_init }

=head3 API specification

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
                                                         runs, or before CHECK fires.

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
	my $owner_pkg = caller;
	if ($_post_check) {
		_process_one($owner_pkg, $_) for @subs;
	} else {
		push @_pending, [ $owner_pkg, $_ ] for @subs;
	}

	return set_return($class, { type => 'string' });
}

# -------------------------------------------------------------------
# CHECK-TIME PROCESSING
# -------------------------------------------------------------------

# Process all declarative wraps queued during import().
# After this fires, $_post_check=1 so future import() calls wrap immediately.
CHECK {
	$_post_check = 1;
	_process_one(@$_) for @_pending;
	@_pending = ();
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

	no strict 'refs';

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
C<\&Foo::_helper>) bypasses the check.  The attribute form prevents this
because wrapping happens at CHECK time.

=item C<enforce> mode: C<can()> leaks private method existence

In C<enforce> mode the original sub is replaced by a wrapper closure, so
C<< ->can('_helper') >> returns the wrapper (truthy) even to callers outside
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

L<Carp> (core),
L<Attribute::Handlers> (core since 5.8),
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

=item * L<namespace::clean>

=back

=head2 FORMAL SPECIFICATION

The following Z-notation schemas formally specify the C<CheckAccess>
operation.

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

=item * Search CPAN

L<https://search.cpan.org/dist/Sub-Private>

=back

=head2 FORMAL SPECIFICATION

=head3 import

    -- Type abbreviations
    SubName == seq CHAR      -- non-empty Perl identifier string

    -- Valid identifier predicate
    valid_id : SubName -> BOOL
    valid_id(n) <=> n =~ /\A[_a-zA-Z]\w*\z/

    -- Pre-condition (declarative form)
    +-ImportPre-----------------------------------------+
    | config.mode = 'enforce'                           |
    | forall n in subs . valid_id(n)                    |
    | forall n in subs . defined(&{caller + '::' + n})  |
    +---------------------------------------------------+

    -- Post-condition (pre-CHECK path)
    +-ImportPost_PreCheck-------------------------------+
    | @_pending' = @_pending                            |
    |            union { (caller, n) | n in subs }      |
    +---------------------------------------------------+

    -- Post-condition (post-CHECK path)
    +-ImportPost_PostCheck------------------------------+
    | forall n in subs .                                |
    |   stash(caller, n) = wrapper_closure(caller, n)   |
    +---------------------------------------------------+

=head1 COPYRIGHT & LICENSE

Copyright 2009 Peter Makholm, all rights reserved.
Portions copyright 2024-2026 Nigel Horne.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
