package Sub::Abstract;

# Minimum Perl version: 5.8 (Attribute::Handlers became core in 5.8)
use 5.008;
use strict;
use warnings;
use autodie qw(:all);

use Attribute::Handlers;
use Carp              qw(croak);
use Readonly;
use Params::Validate::Strict 0.33 qw(validate_strict);
use Return::Set       qw(set_return);

=head1 NAME

Sub::Abstract - Abstract (virtual) methods for plain-Perl OO

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

# Self-referential constant: the canonical name of this package.
Readonly::Scalar my $SELF => __PACKAGE__;

# Validation schema for a single Perl sub name passed to import().
Readonly::Scalar my $SUB_NAME_SCHEMA => {
	name => {
		type  => 'string',
		regex => qr/\A[_a-zA-Z]\w*\z/,
	}
};

# ---------------------------------------------------------------------------
# Public variables
# ---------------------------------------------------------------------------

our $BYPASS = 0;

our %config = (
	harness_bypass => 1,
);

# ---------------------------------------------------------------------------
# Internal state
# ---------------------------------------------------------------------------

# Pending (owner_pkg, sub_name) pairs to be wrapped at CHECK time.
# Populated by import(); consumed and cleared by the CHECK block.
my @_pending;

# Set to 1 once the CHECK block fires so import() can wrap immediately.
my $_post_check = 0;

# -------------------------------------------------------------------
# ATTRIBUTE HANDLER
# -------------------------------------------------------------------

# Install :Abstract in UNIVERSAL so every package can use it after a
# single "use Sub::Abstract", with no per-package setup required.
# ATTR(CODE,CHECK) fires at CHECK time, after all subs are compiled.
# The stub body on the decorated sub is required so that Attribute::Handlers
# has a CODE ref to work with; the handler replaces it unconditionally.
sub UNIVERSAL::Abstract :ATTR(CODE,CHECK) {
	my ($package, $symbol, $referent, $attr, $data, $phase) = @_;
	my $sub_name = *{$symbol}{NAME};
	no warnings 'redefine';
	*{$symbol} = _wrap($package, $sub_name);
	return;
}

# -------------------------------------------------------------------
# PUBLIC INTERFACE
# -------------------------------------------------------------------

=head1 SYNOPSIS

    package Animal;
    use Sub::Abstract;

    # Attribute form (stub body required for Attribute::Handlers)
    sub speak :Abstract { }
    sub eat   :Abstract { }

    # Declarative form (no stub body needed)
    use Sub::Abstract qw(speak eat);

    package Dog;
    our @ISA = ('Animal');
    sub speak { 'Woof' }    # satisfies the contract; wrapper never fires
    # forgot eat -- runtime croak when called

=head1 DESCRIPTION

Enforces abstract (virtual) method contracts for plain-Perl OO without
requiring Moose or Moo.  A subroutine decorated with C<:Abstract> (or
named in C<use Sub::Abstract qw(...)>) is replaced at C<CHECK> time with
a wrapper that C<Carp::croak>s whenever it is reached.

Perl's MRO ensures the wrapper is only reached when no subclass in the
call chain has provided an implementation: if C<Dog::speak> exists, the
wrapper installed in C<Animal::speak> is never called.

This module is only meaningful for plain-Perl OO or packages that do not
use a full object framework.  Moo and Moose handle abstract/required
methods in their own object systems.

=head2 Two usage forms

=over 4

=item Attribute form (preferred)

    sub speak :Abstract { }

The C<:Abstract> attribute is registered in C<UNIVERSAL> via
L<Attribute::Handlers> when C<Sub::Abstract> is loaded, so every package
has access to it without further C<use> or inheritance.  A stub body
(even an empty one) is required because C<Attribute::Handlers> needs a
C<CODE> ref.  The stub is replaced at C<CHECK> time.

=item Declarative form

    use Sub::Abstract qw(speak eat);

Each named method is installed as an abstract-croak wrapper at C<CHECK>
time (or immediately if the module is loaded past C<CHECK>).  No stub body
is needed.

=back

=head2 Bypass for testing

Either condition alone (OR logic) suppresses the croak:

=over 4

=item * C<$Sub::Abstract::BYPASS> set to a true value.  Use C<local> in tests.

=item * C<$ENV{HARNESS_ACTIVE}> set (the convention used by L<Test::Harness>/prove).

=back

The C<HARNESS_ACTIVE> bypass can be disabled:

    $Sub::Abstract::config{harness_bypass} = 0;

=head2 Error message format

    speak() is an abstract method of Animal and must be implemented by Dog

=head1 PUBLIC INTERFACE

=head2 import

    use Sub::Abstract;                   # attribute form -- no arguments
    use Sub::Abstract qw(speak eat);    # declarative form

=head3 Purpose

With B<no arguments>: makes the C<:Abstract> attribute globally available.

With B<one or more method names>: installs abstract-croak wrappers for
those methods in the calling package at C<CHECK> time (or immediately if
C<CHECK> has already fired).

=head3 Arguments

=over 4

=item C<@methods> (optional)

Zero or more Perl sub names, each matching C</\A[_a-zA-Z]\w*\z/>.

=back

=head3 Returns

The class name (C<'Sub::Abstract'>) as a plain string.

=head3 MESSAGES

    Message                                              Meaning
    ---------------------------------------------------  -----------------------------------------------
    "Sub::Abstract->import: 'NAME' is not a valid        A name failed the identifier regex.
     Perl identifier"

=cut

sub import {
	my ($class, @subs) = @_;

	# No sub names: the :Abstract attribute is always available via UNIVERSAL.
	return set_return($class, { type => 'string' }) unless @subs;

	# Validate every name before touching the stash (fail-fast, all-or-nothing).
	for my $sub_name (@subs) {
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

# _process_one
# Purpose      : Install an abstract-croak wrapper for a named method in a package.
# Entry        : $owner_pkg -- the package that declares the abstract method
#                $sub_name  -- the unqualified method name to wrap
# Exit status  : Returns normally; the stash entry is replaced with a wrapper.
# Side effects : Modifies the package stash for $owner_pkg.
# Notes        : Unlike Sub::Private/_process_one, no pre-existence check is done:
#                the declarative form is the normal case where no body exists yet.
sub _process_one {
	my ($owner_pkg, $sub_name) = @_;

	_assert_private_caller('_process_one')
		unless $BYPASS || ($config{harness_bypass} && $ENV{HARNESS_ACTIVE});

	no strict 'refs';
	no warnings 'redefine';
	*{"${owner_pkg}::${sub_name}"} = _wrap($owner_pkg, $sub_name);
	return;
}

# _wrap
# Purpose      : Build an abstract-enforcement wrapper closure.
# Entry        : $owner_pkg -- the package that declares the abstract method
#                $sub_name  -- the unqualified method name (for error messages)
# Exit status  : Returns a new coderef that croaks with a descriptive message
#                naming the invocant class, unless a bypass is active.
# Notes        : Unlike Sub::Private/_wrap there is no $code argument and no
#                goto: the wrapper never delegates because calling an abstract
#                method is always an error.  ref($_[0])||$_[0] extracts the
#                invocant so the error names the concrete class (e.g. Dog),
#                not the abstract base (Animal).
sub _wrap {
	my ($owner_pkg, $sub_name) = @_;

	_assert_private_caller('_wrap')
		unless $BYPASS || ($config{harness_bypass} && $ENV{HARNESS_ACTIVE});

	return sub {
		return if $BYPASS;
		return if $config{harness_bypass} && $ENV{HARNESS_ACTIVE};
		my $invocant = ref($_[0]) || $_[0] // '<undef>';
		croak "${sub_name}() is an abstract method of ${owner_pkg}"
			. " and must be implemented by ${invocant}";
	};
}

# _assert_private_caller
# Purpose      : Croak if a guarded private method was called from outside
#                Sub::Abstract.
# Entry        : $method_name -- the guarded method name (for error messages)
# Exit status  : Returns normally if caller(1) is Sub::Abstract; croaks otherwise.
sub _assert_private_caller {
	my ($method_name) = @_;
	my $caller = (caller(1))[0] // q{};
	return if $caller eq $SELF;
	croak "${method_name}() is a private method of $SELF"
		. " and cannot be called from ${caller}";
}

1;

__END__

=head1 KNOWN LIMITATIONS

=over 4

=item Runtime-only

Checks are runtime only.  There is no compile-time scan of C<@ISA> trees
to verify that all abstract methods are implemented -- that would require
knowing all subclasses at compile time, which is not possible in general Perl.

=item C<can()> returns the croak-stub

Because the stash entry is replaced with a wrapper closure,
C<< Animal->can('speak') >> returns the wrapper (truthy) rather than
C<undef>.  A future release may add a caller-aware C<can()> override.

=item UNIVERSAL namespace pollution

The C<:Abstract> attribute is installed in C<UNIVERSAL>, which means
C<UNIVERSAL::Abstract> is added to the global namespace.

=item Not for Moo/Moose

Moo and Moose handle required/abstract methods in their own object systems.
This module is for plain-Perl OO only.

=back

=head1 DEPENDENCIES

L<Carp> (core),
L<Attribute::Handlers> (core since 5.8),
L<Readonly>,
L<Params::Validate::Strict>,
L<Return::Set>.

=head1 SEE ALSO

=over 4

=item * L<Test Dashboard|https://nigelhorne.github.io/Sub-Abstract/coverage/>

=item * L<Sub::Private>

Sister module enforcing strictly private (owner-only) access.

=item * L<Sub::Protected>

Sister module enforcing protected (owner + subclass) access.

=back

=head1 PUBLIC VARIABLES

=head2 C<$BYPASS>

Set to a true value to disable the abstract-method croak for all wrapped
subs.  Use C<local> in tests:

    local $Sub::Abstract::BYPASS = 1;

=head2 C<%config>

=over 4

=item C<harness_bypass> (default: 1)

When true, the abstract-method croak is suppressed whenever
C<$ENV{HARNESS_ACTIVE}> is set (the convention used by L<Test::Harness>/prove).
Set to 0 to test enforcement from within a test harness.

=back

=cut

=head1 FORMAL SPECIFICATION

The following Z-notation schemas formally specify the C<AbstractCroak>
operation.

    -- Type abbreviations
    Package  == seq CHAR     -- a non-empty Perl package name string
    SubName  == seq CHAR     -- a Perl identifier string

    -- System state
    +-Registry-------------------------------------------+
    | abstract  : P (Package x SubName)                  |
    | bypass    : BOOL                                   |
    | config    : { harness_bypass : BOOL }              |
    +----------------------------------------------------+

    -- Initial state
    +-InitRegistry---------------------------------------+
    | Registry                                           |
    |----------------------------------------------------|
    | abstract  = {}                                     |
    | bypass    = false                                  |
    | config    = { harness_bypass |-> true }            |
    +----------------------------------------------------+

    -- Bypass predicate
    bypass_active(R) <=>
        R.bypass or (R.config.harness_bypass and HARNESS_ACTIVE)

    -- AbstractCroak: fires when the wrapper is reached (no override in MRO)
    +-AbstractCroak--------------------------------------+
    | Xi-Registry                                        |
    | invocant? : Package                                |
    | owner?    : Package                                |
    | name?     : SubName                                |
    |----------------------------------------------------|
    | (owner?, name?) in abstract                        |
    | not bypass_active =>                               |
    |   croak("name?()" ++ " is an abstract method of " |
    |          ++ owner? ++ " and must be implemented by"|
    |          ++ invocant?)                             |
    +----------------------------------------------------+

    -- Key difference from Sub::Private / Sub::Protected:
    --   No caller check is performed.  The wrapper always croaks
    --   because reaching it means no subclass provided an implementation.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it, please let me know.

=cut
