package Sub::Protected;

# Minimum Perl version: 5.10 (the // operator; several dependencies need it).
# Loading after CHECK (require, string eval) also needs 5.14: see LIMITATIONS.
use 5.010;
use strict;
use warnings;

use Carp              qw(croak);
use Attribute::Handlers;
use Readonly;
use Params::Get       qw(get_params);
use Params::Validate::Strict 0.33 qw(validate_strict);
use Return::Set       qw(set_return);

our $VERSION = '0.03';

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
# If this module is itself loaded after CHECK (run-time require, plugin
# loader, string eval) our CHECK block never runs, so start from the global
# phase.  ${^GLOBAL_PHASE} exists from Perl 5.14; on older Perls it is undef
# and the flag starts at 0, so the module must be loaded at compile time.
my $_post_check = (defined(${^GLOBAL_PHASE}) && ${^GLOBAL_PHASE} ne 'START') ? 1 : 0;

# -------------------------------------------------------------------
# ATTRIBUTE HANDLER
# -------------------------------------------------------------------

# Another module may already own UNIVERSAL::Protected (a :Protected attribute
# of its own).  Redefining it would silently change that module's behaviour,
# so say so loudly.  This runs before the sub below is compiled.
BEGIN {
	Carp::carp(__PACKAGE__ . ": UNIVERSAL::Protected is already defined; another module's :Protected attribute will be replaced")
		if defined &UNIVERSAL::Protected;
}

# Install the :Protected attribute in UNIVERSAL so every package can use it
# the moment this module is loaded, with no per-package setup needed.
# Attribute::Handlers calls this sub at CHECK phase for each decorated symbol.
# It is also called at BEGIN phase: before CHECK that call does nothing (the
# CHECK-phase call does the work), but after CHECK the CHECK-phase call never
# happens, so the BEGIN-phase call wraps the sub instead.  The sub is still
# being compiled at that point and may have no name yet, so the wrapping is
# deferred to the end of the scope (normally the file) being compiled.
# on_scope_end() works here because a BEGIN-phase handler runs while the
# user's file is being compiled; it does NOT work from a CHECK-phase callback.
# The unused parameters ($attr, $data) are required by the protocol.
sub UNIVERSAL::Protected : ATTR(CODE,BEGIN,CHECK) {
	my ($package, $symbol, $referent, $attr, $data, $phase) = @_;

	if($phase eq 'BEGIN') {
		return unless($_post_check);	# CHECK will do it
		require B::Hooks::EndOfScope;
		require Sub::Identify;
		B::Hooks::EndOfScope::on_scope_end(sub {
			my ($pkg, $name) = Sub::Identify::get_code_info($referent);
			no strict 'refs';
			UNIVERSAL::Protected($pkg, \*{"${pkg}::$name"}, $referent, $attr, $data, 'CHECK');
		});
		return;
	}

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

0.03

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
wrapped at C<CHECK> time, or, if the module is loaded after C<CHECK> (Perl
5.14 or later), at the end of the file being compiled.  This form is preferred because the protection
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

The error is raised with L<Carp/croak>, so it reports the file and line of
the offending call, not a line inside Sub::Protected.

=head2 How access is decided

=over 4

=item * Only the immediate caller counts

The decision is made on the package of the code that called the protected
sub.  If C<Bar::run> calls C<Foo::public>, which calls C<Foo::_helper>, the
call is allowed: the immediate caller is C<Foo>.  If C<Foo::public> instead
calls a C<Bar> method that calls C<Foo::_helper>, it is blocked, however
deep the chain.

=item * Subclasses are allowed

A caller whose package C<isa> the owner is allowed, so calls through
C<SUPER::>, C<< $self->can('_helper') >> and ordinary inherited method
calls all work from a subclass.

=item * The wrapper is invisible

The wrapper hands over with C<goto &sub>, so inside the protected sub
C<caller()> reports the real caller, not Sub::Protected.  Arguments
(including aliasing of C<@_>), calling context (list, scalar or void) and
return values, including false ones, pass through unchanged.

=back

=head1 PUBLIC INTERFACE

=head2 import

    use Sub::Protected;                    # attribute form -- no arguments
    use Sub::Protected qw(_a _b _c);      # declarative form

=head3 Purpose

Called automatically by C<use Sub::Protected>.

With B<no arguments>: does nothing beyond making the C<:Protected> attribute
globally available (which happens when the module is first loaded).

With B<one or more sub names>: registers those subs in the calling
package for wrapping at C<CHECK> time.  If C<CHECK> has already fired
(e.g. the module was loaded via runtime C<require>, a plugin loader or a
string C<eval>), wrapping is applied immediately.
Each named sub must be defined before C<CHECK> fires (for pre-CHECK loads)
or before C<import> is called (for post-CHECK loads), so a module loaded at
run time should call C<< Sub::Protected->import(...) >> at the end of the
file, after its subs are defined.

Run-time loading needs Perl 5.14 or later.  On older Perls the module must
be loaded at compile time (C<use>, or C<require> inside C<BEGIN>).

=head3 Arguments

=over 4

=item C<$class> (positional, required)

The name of the importing class.  Set automatically by the C<use> mechanism.
Must be a non-empty string.

=item C<@subs> (positional, optional)

Zero or more sub names to protect in the calling package.  Each must be a
valid Perl identifier: matching C</\A[_a-zA-Z]\w*\z/>.

These calls are equivalent:

    Sub::Protected->import(qw(_a _b));
    Sub::Protected->import([ qw(_a _b) ]);
    Sub::Protected->import({ subs => [ qw(_a _b) ] });

A plain list is always a list of names, so C<qw(subs _x)> protects both
C<subs> and C<_x>.  A single arrayref or hashref is normalised by
L<Params::Get>.

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

=item *

C<$@>, C<$!> and C<$_> are left unchanged, as are any pending C<alarm()>
timers.

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
                                                 NAME is shown as '' when the
                                                 name was undef or a reference.

    "Sub::Protected: PKG::NAME is not defined"  The named sub was not found in the
                                                 package stash at wrap time.  For
                                                 pre-CHECK loads, ensure the sub is
                                                 a compile-time named sub.  For
                                                 post-CHECK/runtime loads, ensure
                                                 the sub is defined before import().

Calling a protected sub from outside its package or subclasses croaks
with the message shown in L</Error message format>.

=encoding utf8

=head3 FORMAL SPECIFICATION

    ValidName ≙ { n : seq CHAR | n matches /\A[_a-zA-Z]\w*\z/ }

    ┌─ Import ──────────────────────────────────────────
    │ ΔRegistry
    │ class? : Package ; caller? : Package
    │ names? : seq SubName ; postCheck : 𝔹
    │ result! : Package
    ├───────────────────────────────────────────────────
    │ ∀ n ∈ ran names? • n ∈ ValidName
    │ postCheck ⇒ (∀ n ∈ ran names? • defined(caller?, n))
    │ postCheck ⇒ protected′ = protected ∪ { n : ran names? • (caller?, n) }
    │ ¬postCheck ⇒ pending′ = pending ⁀ ⟨ n : names? • (caller?, n) ⟩
    │ result! = class?
    └───────────────────────────────────────────────────

    -- Failure cases (croak, Registry unchanged):
    --   ∃ n ∈ ran names? • n ∉ ValidName
    --     ⇒ "Sub::Protected->import: 'n' is not a valid Perl identifier"
    --   postCheck ∧ ∃ n ∈ ran names? • ¬defined(caller?, n)
    --     ⇒ "Sub::Protected: caller?::n is not defined"

=cut

sub import {
	my ($class, @subs) = @_;

	# No sub names: the :Protected attribute is always active via UNIVERSAL.
	return _return_class($class) unless @subs;

	# A plain list is always a list of names.  Only a single arrayref or
	# hashref goes through Params::Get: passing a plain list to it would read
	# qw(subs _x) as subs => '_x', silently leaving a sub called subs open.
	my @names = @subs;
	if (@subs == 1 && ref($subs[0]) && ref($subs[0]) ne 'CODE') {
		my $args = get_params('subs', \@subs);
		@names = ref($args->{subs}) eq 'ARRAY'
			? @{$args->{subs}}
			: ($args->{subs});
	}

	# Validate each name against the schema; validate_strict croaks on failure.
	# Params::Validate::Strict silently accepts undef for type => 'string', so
	# we coerce undef and references to '' so the regex check fires for them.
	# local $@ so a successful eval does not clear the caller's $@.
	for my $sub_name (@names) {
		my $check = (defined $sub_name && !ref $sub_name) ? $sub_name : q{};
		my $valid = do {
			local $@;
			eval { validate_strict(schema => $SUB_NAME_SCHEMA, input => { name => $check }); 1 };
		};
		croak "$SELF->import: '$check' is not a valid Perl identifier"
			unless $valid;
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

	return _return_class($class);
}

# -------------------------------------------------------------------
# CHECK-TIME PROCESSING
# -------------------------------------------------------------------

# Process all pending declarative wraps registered during import().
# After processing, set the post_check flag so runtime imports wrap directly.
# The bare block silences "Too late to run CHECK block" when this module is
# loaded after CHECK; $_post_check is already 1 in that case.
{
	no warnings 'void';	# "Too late to run CHECK block"
	CHECK {
		$_post_check = 1;

		# Wrap every pending (package, sub) pair.
		_process_one(@$_) for @_pending;
		@_pending = ();
	}
}

# -------------------------------------------------------------------
# PRIVATE SUBROUTINES
# -------------------------------------------------------------------

# _return_class
# Purpose:    Validate and return import()'s return value.
# Entry:      ($class) -- the importing class name.
# Exit:       Returns $class, checked against the documented string schema.
# Notes:      Return::Set::set_return clears $@ even when it succeeds, and
#             import() promises to leave $@ alone, so it is localised here.
sub _return_class {
	my ($class) = @_;

	local $@;
	return set_return($class, { type => 'string' });
}

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

=item Run-time loading on Perl < 5.14

On Perls older than 5.14, loading this module (or a package that uses it)
at run time -- via C<require>, a plugin loader or a string C<eval> -- leaves
the subs unprotected, because C<CHECK> has already fired.  Load it at
compile time instead.

=item UNIVERSAL namespace pollution

The C<:Protected> attribute is installed in C<UNIVERSAL>, which is
intentional (any package can use it after a single C<use>), but it does
introduce C<UNIVERSAL::Protected> into the global namespace.  If another
module has already defined C<UNIVERSAL::Protected>, loading Sub::Protected
warns that it is being replaced.

=item Thread safety

C<@_pending> and C<$BYPASS> are unguarded package globals.  Subs are
normally wrapped before any thread is started, which is safe.  Calling
C<< Sub::Protected->import(...) >> or loading a package that uses
Sub::Protected from more than one thread at once is not supported.
C<$BYPASS> is per-thread, as with any C<our> variable under ithreads.

=back

=head1 DEPENDENCIES

L<Carp> (core),
L<Attribute::Handlers> (core since 5.8),
L<B::Hooks::EndOfScope>,
L<Readonly>,
L<Sub::Identify>,
L<Params::Get>,
L<Params::Validate::Strict>,
L<Return::Set>.

=head1 SEE ALSO

=over 4

=item * L<Test Dashboard|https://nigelhorne.github.io/Sub-Protected/coverage/>

=item * L<Sub::Abstract>

Sister module enforcing abstract (virtual) methods

=item * L<Sub::Private>

Sister module enforcing strictly private (owner-only) access.

=back

L<Attribute::Handlers>, L<Carp>, L<Readonly>, L<Params::Get>,
L<Params::Validate::Strict>, L<Return::Set>.

=head1 FORMAL SPECIFICATION

=head2 import

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

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
