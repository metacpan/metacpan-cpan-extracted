package Sub::Protected;

# Minimum Perl version: 5.8 (Attribute::Handlers became core in 5.8)
use 5.008;
use strict;
use warnings;
use autodie qw(:all);

use Carp              qw(croak carp);
use Attribute::Handlers;
use Readonly;
use Scalar::Util      qw(blessed);
use Params::Get       qw(get_params);
use Params::Validate::Strict qw(validate_strict);
use Return::Set       qw(set_return);

our $VERSION = '0.01';

# Public bypass flag.  Set to a true value to disable all access checks.
# Use C<local $Sub::Protected::BYPASS = 1> in test code; see BYPASS section.
our $BYPASS = 0;

# Module-level configuration hash.
# Can be modified directly or injected via Object::Configure.
our %config = (
	# When true, access checks are skipped if $ENV{HARNESS_ACTIVE} is set.
	# Set to 0 to test protection behaviour from within a test harness.
	harness_bypass => 1,
);

# Self-referential constant: the name of this package.
# Used to identify our own frames in the call-stack walk.
Readonly::Scalar my $SELF => __PACKAGE__;

# Validation schema for a single Perl sub name passed to import().
Readonly::Scalar my $SUB_NAME_SCHEMA => {
	name => {
		type  => 'string',
		regex => qr/\A[_a-zA-Z]\w*\z/,
	}
};

# Pending (owner_pkg, sub_name) pairs to be wrapped at CHECK time.
# Populated by import(); consumed and cleared by the CHECK block.
my @_pending;

# Set to 1 when the CHECK block fires.  Import() uses this to decide
# whether to schedule wrapping (pre-CHECK) or wrap immediately (post-CHECK).
my $_post_check = 0;

# -------------------------------------------------------------------
# ATTRIBUTE HANDLER
# -------------------------------------------------------------------

# Install the :Protected attribute in UNIVERSAL so every package can use it
# the moment this module is loaded, with no per-package setup needed.
# Attribute::Handlers calls this sub at CHECK phase for each decorated symbol.
# The unused parameters ($attr, $data) are required by the protocol.
sub UNIVERSAL::Protected : ATTR(CODE,CHECK) {
	my ($package, $symbol, $referent, $attr, $data, $phase) = @_;
	my $sub_name = *{$symbol}{NAME};
	no warnings 'redefine';
	*{$symbol} = _wrap($package, $sub_name, $referent);  # function call, not method call
	return;
}

# -------------------------------------------------------------------
# PUBLIC INTERFACE
# -------------------------------------------------------------------

=head1 NAME

Sub::Protected - Enforce protected subroutine access (Java/C++ semantics)

=head1 VERSION

0.01

=head1 SYNOPSIS

    package Foo;
    use Sub::Protected;              # enables the :Protected attribute

    sub new { bless {}, shift }

    # Attribute form (preferred: protection lives next to the definition)
    sub _helper :Protected {
        ...
    }

    sub public_method {
        my $self = shift;
        $self->_helper;              # OK -- same package
    }

    # ----------------------------------------------------------------

    package Bar;
    use Sub::Protected qw(_other _private);   # declarative form

    sub _other   { 'other'   }
    sub _private { 'private' }

=head1 DESCRIPTION

Enforces Java/C++-style "protected" access at runtime: a subroutine
decorated with C<:Protected> (or named in C<use Sub::Protected qw(...)>)
may only be called from within its defining package or from a subclass of
that package.  Any other caller causes a C<Carp::croak> with a descriptive
message.

=head2 Two usage forms

=over 4

=item Attribute form (preferred)

    sub _helper :Protected { ... }

The C<:Protected> attribute is registered in C<UNIVERSAL> via
L<Attribute::Handlers> when C<Sub::Protected> is loaded, so every package
has access to it without any further C<use> or inheritance.  The sub is
wrapped at C<CHECK> time.  This form is preferred because the protection
declaration sits next to the definition and wrapping happens at compile time
(making pre-wrap raw-coderef captures impossible).

=item Declarative form

    use Sub::Protected qw(_helper _other);

Each named sub is looked up in the caller's stash and wrapped at C<CHECK>
time (or immediately if the module is loaded at runtime via C<require>).
All named subs must be defined before C<CHECK> fires -- i.e. they must be
compile-time named subs in the same file, not generated at runtime.

=back

=head2 Bypass for testing

Either condition alone (OR logic) disables all access checks:

=over 4

=item * C<$Sub::Protected::BYPASS> set to a true value.  Use C<local> in tests.

=item * C<$ENV{HARNESS_ACTIVE}> set (the convention used by L<Test::Harness>/prove).

=back

C<$Sub::Protected::BYPASS> is the recommended form for new test code;
it is explicit and does not depend on the test runner.
C<HARNESS_ACTIVE> is a zero-config convenience.

The HARNESS_ACTIVE bypass can be disabled by setting:

    $Sub::Protected::config{harness_bypass} = 0;

=head2 Configuration

The module exposes C<%Sub::Protected::config> for runtime configuration:

=over 4

=item C<harness_bypass> (default: 1)

When true, access checks are skipped whenever C<$ENV{HARNESS_ACTIVE}> is
set.  Set to 0 to test protection behaviour from within a test harness.

=back

The hash is compatible with L<Object::Configure> for dependency-injection
scenarios.

=head2 Error message format

    _helper() is a protected method of Foo and cannot be called from Bar

=head1 PUBLIC INTERFACE

=head2 import

    use Sub::Protected;                    # attribute form -- no arguments
    use Sub::Protected qw(_a _b _c);      # declarative form

=head3 Purpose

Called automatically by C<use Sub::Protected>.

With B<no arguments>: does nothing beyond making the C<:Protected> attribute
globally available (which happens when the module is first loaded).

With B<one or more sub names>: registers those subs in the calling
package for wrapping at C<CHECK> time.  If the module has already passed
C<CHECK> (e.g. loaded via runtime C<require>), wrapping occurs immediately.
Each named sub must be defined before C<CHECK> fires (for pre-CHECK loads)
or before C<import> is called (for post-CHECK loads).

=head3 Arguments

=over 4

=item C<$class> (positional, required)

The name of the importing class.  Set automatically by the C<use> mechanism.
Must be a non-empty string.

=item C<@subs> (positional, optional)

Zero or more sub names to protect in the calling package.  Each must be a
valid Perl identifier: matching C</\A[_a-zA-Z]\w*\z/>.

=back

=head3 Returns

C<$class> (the importing class name).  The return value is ignored by the
C<use> mechanism; it is provided for optional method chaining at the class
level.

=head3 Side effects

=over 4

=item *

Each supplied sub name is appended to an internal pending list (if pre-CHECK)
or wrapped immediately (if post-CHECK).

=item *

The pending list is consumed and cleared when the CHECK block fires.

=back

=head3 Example

    package Foo;
    use Sub::Protected qw(_helper _init);

    sub _helper { ... }   # will be protected
    sub _init   { ... }   # will be protected

=head3 API SPECIFICATION

=head4 Input

    # Params::Get::get_params / Params::Validate::Strict schema
    {
        # class is the implicit first argument, set by Perl's 'use' mechanism
        subs => {
            type     => 'array',
            required => 0,
            each     => {
                type  => 'string',
                regex => qr/\A[_a-zA-Z]\w*\z/,
            },
        },
    }

=head4 Output

    # Return::Set schema
    {
        type    => 'string',
        desc    => 'The importing class name ($class), for optional chaining.',
    }

=head3 MESSAGES

The following table lists every error or warning this method can produce.

    Message                                     Meaning
    ----------------------------------------	-------------------------------------
    "Sub::Protected->import: 'NAME' is not a    A sub name passed to import() failed
     valid Perl identifier"                      the identifier regex.  Use a name
                                                 matching /\A[_a-zA-Z]\w*\z/.

    "Sub::Protected: PKG::NAME is not defined"  The named sub was not found in the
                                                 package stash at wrap time.  For
                                                 pre-CHECK loads, ensure the sub is
                                                 a compile-time named sub.  For
                                                 post-CHECK/runtime loads, ensure
                                                 the sub is defined before import().

=cut

sub import {
	my ($class, @subs) = @_;

	# No sub names: the :Protected attribute is always active via UNIVERSAL.
	return set_return($class, { type => 'string' }) unless @subs;

	# Normalise the argument list to support positional and hash-ref styles.
	my $args = get_params('subs', \@subs);
	my @names = ref($args->{subs}) eq 'ARRAY'
		? @{$args->{subs}}
		: ($args->{subs});

	# Validate each name against the schema; validate_strict croaks on failure.
	for my $sub_name (@names) {
		eval { validate_strict(schema => $SUB_NAME_SCHEMA, input => { name => $sub_name }) };
		croak "$SELF->import: '$sub_name' is not a valid Perl identifier"
			if $@;
	}

	# Schedule or immediately apply wrapping depending on compilation phase.
	my $owner_pkg = caller;
	if ($_post_check) {
		# Module was loaded at runtime (past CHECK): wrap immediately.
		_process_one($owner_pkg, $_) for @names;
	} else {
		# Pre-CHECK: register for the CHECK block to process.
		push @_pending, [ $owner_pkg, $_ ] for @names;
	}

	return set_return($class, { type => 'string' });
}

# -------------------------------------------------------------------
# CHECK-TIME PROCESSING
# -------------------------------------------------------------------

# Process all pending declarative wraps registered during import().
# After processing, set the post_check flag so runtime imports wrap directly.
CHECK {
	$_post_check = 1;

	# Wrap every pending (package, sub) pair.
	_process_one(@$_) for @_pending;
	@_pending = ();
}

# -------------------------------------------------------------------
# PRIVATE SUBROUTINES
# -------------------------------------------------------------------

# _process_one
# Purpose:    Look up a named sub in a package's stash and wrap it.
#             Called from the CHECK block and from import() (post-CHECK).
# Entry:      ($owner_pkg, $sub_name) -- both non-empty strings;
#             $owner_pkg::$sub_name must be defined in the stash.
# Exit:       The stash entry is replaced with the wrapper closure.
#             Croaks if the sub is not defined.
# Side effects: Modifies the caller package's stash (redefines the named glob).
# Notes:      Uses 'no warnings redefine' because the whole point is replacement.
sub _process_one {
	my ($owner_pkg, $sub_name) = @_;

	# Guard: only Sub::Protected code should call this.
	_assert_private_caller('_process_one')
		unless $BYPASS || ($config{harness_bypass} && $ENV{HARNESS_ACTIVE});

	no strict 'refs';

	# Abort clearly when the sub was never defined.
	croak "$SELF: ${owner_pkg}::${sub_name} is not defined"
		unless defined &{"${owner_pkg}::${sub_name}"};

	my $code = \&{"${owner_pkg}::${sub_name}"};
	no warnings 'redefine';
	*{"${owner_pkg}::${sub_name}"} = _wrap($owner_pkg, $sub_name, $code);
	return;
}

# _wrap
# Purpose:    Construct the protection wrapper closure around a coderef.
# Entry:      ($owner_pkg, $sub_name, $code) -- all defined; $code is a CODE ref.
# Exit:       Returns a new anonymous CODE ref (the wrapper closure).
#               At call time: calls _check_access (may croak), then $code.
# Notes:      'goto &$code' is a deliberate, necessary exception to the
#             "avoid goto" guideline.  It replaces the wrapper's stack frame
#             with $code's frame so that caller() inside the protected body
#             sees the real caller, not 'Sub::Protected'.  Replacing with
#             $code->(@_) would make caller(0) return 'Sub::Protected' inside
#             the protected sub, breaking any code there that inspects its
#             caller.  Do NOT change this without updating t/caller_integrity.t.
sub _wrap {
	my ($owner_pkg, $sub_name, $code) = @_;

	# Guard: only Sub::Protected code (and its subclasses) should call _wrap.
	_assert_private_caller('_wrap')
		unless $BYPASS || ($config{harness_bypass} && $ENV{HARNESS_ACTIVE});

	# Return the wrapper.  The goto is load-bearing -- see Notes above.
	return sub {
		Sub::Protected::_check_access($owner_pkg, $sub_name);
		goto &$code;    ## no critic (ControlStructures::ProhibitGoto)
	};
}

# _check_access
# Purpose:    Enforce the protected-access invariant at call time.
#             Walk the call stack (skipping Sub::Protected frames) to find
#             the first external frame, then allow or croak based on the
#             owner/isa relationship.
# Entry:      ($owner_pkg, $sub_name) -- both defined strings.
#             The current stack has the wrapper closure at the top (frame 0),
#             followed by the real caller.
# Exit:       Returns normally (undef) if access is permitted.
#             Croaks with a descriptive message if access is denied.
# Notes:      Frame index starts at 0 (= the wrapper closure that called us).
#             The walk increments until a non-Sub::Protected package appears.
#             This approach is robust against SUPER:: chains, can() delegation,
#             and XS frames that may insert extra frames.
sub _check_access {
	my ($owner_pkg, $sub_name) = @_;

	# Short-circuit on bypass (OR logic: either condition alone is sufficient).
	return if $BYPASS;
	return if $config{harness_bypass} && $ENV{HARNESS_ACTIVE};

	# Walk the stack to find the real (first non-SP) caller.
	my $frame = 0;
	while (1) {
		my $pkg = (caller($frame))[0];

		# No package found: reached the top of the stack.
		if (!defined $pkg) {
			croak "${sub_name}() is a protected method of ${owner_pkg}"
				. ' and cannot be called outside any package context';
		}

		# Skip Sub::Protected's own frames (wrapper closure, _check_access).
		if ($pkg eq $SELF) {
			$frame++;
			next;
		}

		# Found the real caller: allow if owner or subclass, else croak.
		return if $pkg eq $owner_pkg || $pkg->isa($owner_pkg);

		croak "${sub_name}() is a protected method of ${owner_pkg}"
			. " and cannot be called from ${pkg}";
	}
}

# _assert_private_caller
# Purpose:    Croak if the guarded private method was called from outside
#             Sub::Protected (or a subclass).  Used to enforce visibility.
# Entry:      ($method_name) -- name of the guarded method, used in the message.
#             Must be called directly (not nested deeper) inside the guarded method.
# Exit:       Returns normally if the caller is Sub::Protected or a subclass.
#             Croaks with a descriptive message otherwise.
# Side effects: Calls Carp::croak on failure.
# Notes:      caller() semantics from inside this sub:
#               caller(0) -- the package in which the call TO this sub was made.
#                            That is the guarded method's package = Sub::Protected.
#               caller(1) -- the package in which the call TO the guarded method
#                            was made.  That is the actual external caller to check.
sub _assert_private_caller {
	my ($method_name) = @_;

	# caller(1): the package that invoked the guarded method directly.
	my $caller = (caller(1))[0] // q{};
	return if $caller eq $SELF || eval { $caller->isa($SELF) };

	croak "${method_name}() is a private method of $SELF"
		. " and cannot be called from ${caller}";
}

1;

__END__

=head1 KNOWN LIMITATIONS

=over 4

=item Runtime-only

Checks are runtime only; there is no compile-time enforcement.

=item Raw coderef bypass

A raw code reference obtained B<before> wrapping (via C<can()> or direct
C<\&Foo::_helper>) bypasses the check.  The attribute form prevents this
because wrapping happens at compile time.

=item Moo/Moose method modifiers

Method modifiers applied after Sub::Protected has wrapped a sub will wrap
the wrapper.  Apply Sub::Protected last, or use the declarative form in a
C<CHECK> block after the class is fully built.

=item UNIVERSAL namespace pollution

The C<:Protected> attribute is installed in C<UNIVERSAL>, which is
intentional (any package can use it after a single C<use>), but it does
introduce C<UNIVERSAL::Protected> into the global namespace.

=item Thread safety

C<@_pending> and C<$BYPASS> are unguarded package globals.  Do not use
concurrent C<use Sub::Protected qw(...)> calls across threads.

=back

=head1 DEPENDENCIES

L<Carp> (core),
L<Attribute::Handlers> (core since 5.8),
L<Readonly>,
L<Scalar::Util> (core),
L<Params::Get>,
L<Params::Validate::Strict>,
L<Return::Set>.

=head1 SEE ALSO

L<Attribute::Handlers>, L<Carp>, L<Readonly>, L<Params::Get>,
L<Params::Validate::Strict>, L<Return::Set>.

=head2 FORMAL SPECIFICATION

=head3 import

The following Z-notation schemas formally specify the state and operations
of Sub::Protected.  Unicode mathematical symbols are used in this section
only.

    -- Type abbreviations
    Package  == seq CHAR     -- a non-empty Perl package name string
    SubName  == seq CHAR     -- a Perl identifier string
    Proc     == seq CHAR     -- abstract: a callable code reference

    -- Ancestry relation (derived dynamically from @ISA chains)
    anc : Package -> P Package
    forall p : Package .
        anc p = {p} union bigcup { anc r | r in @ISA_of(p) }

    -- Protected-access predicate
    permitted : Package x Package -> BOOL
    forall caller, owner : Package .
        permitted(caller, owner) <=> owner in anc(caller)

    -- System state
    +-Registry-------------------------------------------+
    | protected : P (Package x SubName)                  |
    | bypass    : BOOL                                   |
    | config    : { harness_bypass : BOOL }              |
    +----------------------------------------------------+

    -- Initial state
    +-InitRegistry---------------------------------------+
    | Registry                                           |
    |----------------------------------------------------|
    | protected = {}                                     |
    | bypass    = false                                  |
    | config    = { harness_bypass |-> true }            |
    +----------------------------------------------------+

    -- Wrap: add a sub to the protected registry
    +-Wrap-----------------------------------------------+
    | Delta-Registry                                     |
    | pkg? : Package ; name? : SubName                   |
    |----------------------------------------------------|
    | protected' = protected union { (pkg?, name?) }     |
    | bypass'    = bypass                                |
    | config'    = config                                |
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
    | (owner?, name?) in protected                       |
    | ok! <=> bypass_active or permitted(caller?, owner?)|
    +----------------------------------------------------+

    -- Violation (croak case):
    --   not ok! =>
    --   croak("name?()" ++ " is a protected method of " ++ owner?
    --         ++ " and cannot be called from " ++ caller?)

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2010-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
