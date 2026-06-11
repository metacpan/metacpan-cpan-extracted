#!/usr/bin/perl
# t/extended_tests.t -- coverage-completion tests for Sub::Abstract.
#
# This file targets execution paths that are not hit by the main suite.
# Each section header names the specific gap being closed.
#
# Gaps addressed:
#   1.  TER3: _wrap()/_process_one() guard with BYPASS=1 AND HARNESS_ACTIVE=1
#             simultaneously -- the || short-circuits on BYPASS.
#   2.  _wrap() closure: BYPASS=1 with harness_bypass=0 -- BYPASS wins.
#   3.  import() fail-fast with bad-FIRST ordering (existing tests use good-first).
#   4.  import() fail-fast with middle name invalid (all-or-nothing for 3 names).
#   5.  SUPER:: dispatch reaching the abstract wrapper in the base class.
#   6.  can() returning a callable croak-stub (documented limitation, but calling
#       the returned coderef is not tested elsewhere).
#   7.  Attribute form with a non-trivial stub body -- attribute handler replaces it.
#   8.  Declarative form for AUTOLOAD (attribute form is tested; declarative is not).
#   9.  Single-underscore method name '_' -- valid per /\A[_a-zA-Z]\w*\z/ regex.
#   10. Deeply nested package as abstract owner -- full name in error string.
#   11. harness_bypass=2 (truthy non-1 value) still activates HARNESS_ACTIVE bypass.
#   12. Unblessed GLOB reference as invocant -- ref(\*STDOUT) = 'GLOB'.
#   13. Extra arguments beyond $_[0] do not affect the croak.
#   14. import() with 'import' as the abstract method name.
#
# UNREACHABLE PATH (documented for completeness):
#   _assert_private_caller() line: my $caller = (caller(1))[0] // q{};
#   The '// q{}' branch would fire only if _assert_private_caller were reached
#   with zero frames above its direct caller.  In practice _wrap() and
#   _process_one() are always invoked from within a larger call chain (CHECK
#   block, import(), attribute handler, test code), so (caller(1))[0] always
#   resolves to a defined package name.  This branch is unreachable in portable
#   tests and cannot be triggered without manipulating the C-level call stack.

use strict;
use warnings;

# Taint-safe INC manipulation for local dev copies of Test::Mockingbird etc.
BEGIN {
	my ($home) = ($ENV{HOME} =~ /\A(.+)\z/ms);
	unshift @INC,
		'lib',
		"$home/src/njh/Test-Mockingbird/lib",
		"$home/src/njh/Test-Returns/lib";
}

use Test::Most;
use Test::Returns;
use Scalar::Util qw(reftype blessed);
use Readonly;

# -------------------------------------------------------------------
# Constants -- no magic strings or numbers in this file
# -------------------------------------------------------------------

Readonly::Scalar my $SA => 'Sub::Abstract';

# Configuration values used across multiple subtests.
my %config = (
	impl_result       => 'et_impl',
	computed_result   => 'computed',
	deep_pkg          => 'ET::A::B::C::D::Deep',
	deep_method       => 'deep_op',
	glob_invocant     => 'GLOB',
	single_underscore => '_',
	special_import    => 'import',
	autoload_sub      => 'any_undefined_method',
	harness_bypass_hi => 2,       # truthy non-1 value for harness_bypass
	extra_arg_1       => 'extra1',
	extra_arg_2       => 'extra2',
);

# -------------------------------------------------------------------
# Load the module -- CHECK fires after all fixture packages compile.
# -------------------------------------------------------------------

use Sub::Abstract;

# -------------------------------------------------------------------
# Package fixtures -- ALL at compile time so :Abstract wraps at CHECK.
# All use ET:: prefix to avoid name collisions with other test files.
# -------------------------------------------------------------------

# ===== Shared base fixture used by several sections =====
{
	package ET::Base;
	use Sub::Abstract;
	sub new    { bless {}, shift }
	sub render :Abstract { }
	sub _bare  { 'bare' }    # unwrapped; used in stash-mutation checks
}

# Subclass that implements render() -- wrapper in base never fires.
{
	package ET::Impl;
	our @ISA = ('ET::Base');
	sub new    { bless {}, shift }
	sub render { 'et_impl' }
}

# Subclass that does NOT implement render() -- wrapper fires and croaks.
{
	package ET::NoImpl;
	our @ISA = ('ET::Base');
	sub new { bless {}, shift }
}

# ===== SUPER:: dispatch fixture =====
# ET::SuperBase declares render abstract.
# ET::SuperSub provides render() that immediately delegates to SUPER::render().
{
	package ET::SuperBase;
	use Sub::Abstract;
	sub new    { bless {}, shift }
	sub render :Abstract { }
}

{
	package ET::SuperSub;
	our @ISA = ('ET::SuperBase');
	sub new    { bless {}, shift }
	# render IS defined here (MRO finds it), but it calls SUPER::render,
	# which goes directly to ET::SuperBase::render (the abstract wrapper).
	sub render { my $self = shift; $self->SUPER::render(@_) }
}

# ===== Attribute form with non-trivial stub body =====
# The stub body contains a real return value and dead code.
# The attribute handler must replace the entire body regardless of content.
{
	package ET::NontrivialStub;
	use Sub::Abstract;
	sub new { bless {}, shift }
	# stub contains real code; the handler replaces it unconditionally at CHECK
	sub compute :Abstract { return 99; my $unused = 'dead code'; }
}

{
	package ET::NontrivialImpl;
	our @ISA = ('ET::NontrivialStub');
	sub new     { bless {}, shift }
	sub compute { 'computed' }    # concrete; returns a real value, not 99
}

# ===== Declarative AUTOLOAD =====
# Tests the declarative form of AUTOLOAD (distinct from attribute form in edge_cases.t).
{
	package ET::DeclAutoloadBase;
	use Sub::Abstract qw(AUTOLOAD);    # AUTOLOAD declared abstract -- no stub needed
	sub new { bless {}, shift }
}

{
	package ET::DeclAutoloadImpl;
	our @ISA = ('ET::DeclAutoloadBase');
	sub new      { bless {}, shift }
	sub AUTOLOAD { 'handled' }    # concrete AUTOLOAD -- satisfies the contract
}

# ===== Deeply nested package as abstract owner =====
{
	package ET::A::B::C::D::Deep;
	use Sub::Abstract qw(deep_op);    # declarative form in a deeply nested package
	sub new { bless {}, shift }
}

{
	package ET::A::B::C::D::DeepImpl;
	our @ISA = ('ET::A::B::C::D::Deep');
	sub new     { bless {}, shift }
	sub deep_op { 'deep' }
}

diag "Starting extended coverage tests for $SA" if $ENV{TEST_VERBOSE};

# ===================================================================
# SECTION 1: TER3 guard -- BYPASS=1 AND HARNESS_ACTIVE=1 simultaneously
#
# Guard condition: unless $BYPASS || ($config{harness_bypass} && $HARNESS)
# With BYPASS=1 the || short-circuits; the compound rhs is never evaluated.
# TER3 (Multiple Condition Coverage) requires testing all combinations of
# the sub-conditions.  The (BYPASS=1, HARNESS_ACTIVE=1) case is not
# exercised by any other test file.
# ===================================================================

subtest '_wrap() guard: BYPASS=1 AND HARNESS_ACTIVE=1 simultaneously (TER3)' => sub {
	plan tests => 2;

	# Both bypasses true at once: BYPASS short-circuits the || expression
	local $Sub::Abstract::BYPASS = 1;
	local $ENV{HARNESS_ACTIVE}   = 1;

	diag '_wrap() with BYPASS=1 + HARNESS_ACTIVE=1 (TER3)' if $ENV{TEST_VERBOSE};

	my $wrapper;
	lives_ok {
		$wrapper = Sub::Abstract::_wrap('ET::Base', 'render');
	} '_wrap() guard: skipped when BYPASS=1 AND HARNESS_ACTIVE=1';

	# Guard bypass must return a usable CODE ref
	ok defined($wrapper) && reftype($wrapper) eq 'CODE',
		'_wrap() returns a CODE ref with both bypasses active simultaneously';
};

subtest '_process_one() guard: BYPASS=1 AND HARNESS_ACTIVE=1 simultaneously (TER3)' => sub {
	plan tests => 1;

	# Fresh target to avoid stash conflicts with other subtests
	{ package ET::TER3Target; sub new { bless {}, shift } sub _ter3 { 1 } }

	local $Sub::Abstract::BYPASS = 1;
	local $ENV{HARNESS_ACTIVE}   = 1;

	diag '_process_one() with BYPASS=1 + HARNESS_ACTIVE=1 (TER3)' if $ENV{TEST_VERBOSE};

	lives_ok {
		Sub::Abstract::_process_one('ET::TER3Target', '_ter3');
	} '_process_one() guard: skipped when BYPASS=1 AND HARNESS_ACTIVE=1';
};

# ===================================================================
# SECTION 2: Closure -- BYPASS=1 with harness_bypass=0 (short-circuit)
#
# The closure checks $BYPASS FIRST, then $config{harness_bypass} && $ENV.
# With BYPASS=1 the first "return if $BYPASS" fires unconditionally,
# regardless of the value of harness_bypass.
# ===================================================================

subtest '_wrap() closure: BYPASS=1 suppresses croak even when harness_bypass=0' => sub {
	plan tests => 1;

	# Obtain the wrapper while bypassed (so the guard does not fire)
	my $wrapper;
	{ local $Sub::Abstract::BYPASS = 1;
	  $wrapper = Sub::Abstract::_wrap('ET::Base', 'render'); }

	# Now run the closure with harness_bypass disabled but BYPASS=1
	local $Sub::Abstract::BYPASS                 = 1;
	local $Sub::Abstract::config{harness_bypass} = 0;
	local $ENV{HARNESS_ACTIVE}                   = 0;

	lives_ok { $wrapper->() }
		'closure: BYPASS=1 short-circuits before harness_bypass is consulted';
};

# ===================================================================
# SECTION 3: Fail-fast with bad-FIRST ordering
#
# Existing fail-fast tests all use ('good_name', $bad_name).
# This section uses ($bad_name, 'good_name_after') to verify:
#   * import() croaks on the very first name
#   * the name(s) AFTER the bad one are also NOT wrapped
# ===================================================================

subtest 'import() fail-fast: bad-FIRST -- good names after it are NOT wrapped' => sub {
	plan tests => 2;

	# Fixture with a sub that must remain callable after the failed import
	{ package ET::BadFirst; sub _after_bad { 'after' } }

	# The bad name is first; import() must croak before any wrapping occurs
	throws_ok {
		package ET::BadFirst;
		Sub::Abstract->import('123invalid', '_after_bad');
	} qr/is not a valid Perl identifier/,
		'import() croaks on the first (bad) name in the list';

	# _after_bad must still be callable -- no wrapping occurred (all-or-nothing)
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	lives_ok { ET::BadFirst::_after_bad() }
		'_after_bad NOT wrapped: all-or-nothing stops at first invalid name';
};

# ===================================================================
# SECTION 4: Fail-fast with middle name invalid
#
# ('good1', 'bad-name', 'good2'): neither the first nor the third name
# may be wrapped -- all-or-nothing must apply to the entire list.
# ===================================================================

subtest 'import() fail-fast: middle-invalid -- NO names wrapped (all-or-nothing)' => sub {
	plan tests => 3;

	# Three names; first and third valid, middle invalid
	{ package ET::MiddleBad;
	  sub _mb_first { 'first' }
	  sub _mb_third { 'third' }
	}

	throws_ok {
		package ET::MiddleBad;
		Sub::Abstract->import('_mb_first', 'bad-name', '_mb_third');
	} qr/is not a valid Perl identifier/,
		'import() croaks when the middle name is invalid';

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# Both the pre-invalid and post-invalid names must remain unwrapped
	lives_ok { ET::MiddleBad::_mb_first() }
		'_mb_first NOT wrapped (fail-fast: all-or-nothing for the whole list)';
	lives_ok { ET::MiddleBad::_mb_third() }
		'_mb_third NOT wrapped (fail-fast: names after the bad one are safe too)';
};

# ===================================================================
# SECTION 5: SUPER:: dispatch reaching the abstract wrapper
#
# ET::SuperSub provides render() which calls $self->SUPER::render().
# MRO resolves SUPER::render to ET::SuperBase::render (the wrapper).
# The invocant inside the wrapper is still the ET::SuperSub instance.
# ===================================================================

subtest 'SUPER:: dispatch: calling SUPER::abstract_method() reaches the wrapper' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	diag 'ET::SuperSub::render calls $self->SUPER::render' if $ENV{TEST_VERBOSE};

	# The error must name the method and the abstract base owner
	throws_ok { ET::SuperSub->new->render }
		qr/render\(\) is an abstract method of ET::SuperBase/,
		'SUPER:: dispatch: error names the method and the owner base class';

	# The invocant must be the subclass (the object that initiated the call)
	throws_ok { ET::SuperSub->new->render }
		qr/must be implemented by ET::SuperSub/,
		'SUPER:: dispatch: invocant in error is the subclass, not the base';
};

# ===================================================================
# SECTION 6: can() returns a callable croak-stub
#
# The POD documents: "Animal->can('speak') returns the wrapper (truthy)
# rather than undef."  Other tests verify the truthy return; this
# section goes further and calls the returned coderef directly,
# verifying that calling it produces the expected abstract croak.
# ===================================================================

subtest 'can() stub: returned coderef is callable and croaks with correct message' => sub {
	plan tests => 3;

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# can() must return the wrapper coderef, not undef
	my $stub = ET::Base->can('render');
	ok $stub, 'can("render") returns a truthy value (the croak-stub wrapper)';
	ok defined($stub) && reftype($stub) eq 'CODE',
		'can() return value is a CODE ref (the installed abstract wrapper)';

	# Calling the returned coderef with a non-implementing object must croak
	throws_ok { $stub->(ET::NoImpl->new) }
		qr/render\(\) is an abstract method of ET::Base/,
		'calling the can() stub directly triggers the abstract croak';
};

# ===================================================================
# SECTION 7: Attribute form with a non-trivial stub body
#
# The attribute handler must replace the stub body COMPLETELY at CHECK
# time, regardless of what the body contains.  A stub that says
# "return 99" must NOT return 99; it must croak.
# ===================================================================

subtest 'attribute form: non-trivial stub body is replaced by the abstract wrapper' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	diag 'ET::NontrivialStub::compute stub has "return 99" but must croak' if $ENV{TEST_VERBOSE};

	# The stub says return 99, but the attribute handler replaced it -- must croak
	throws_ok { ET::NontrivialStub->new->compute }
		qr/compute\(\) is an abstract method of ET::NontrivialStub/,
		'non-trivial stub body: wrapper fires instead of the original stub code';

	# The implementing subclass must use its own return value, not 99 from the stub
	lives_and { is(ET::NontrivialImpl->new->compute, $config{computed_result}) }
		'implementing subclass: returns its own value, not the stub 99';
};

# ===================================================================
# SECTION 8: Declarative AUTOLOAD
#
# edge_cases.t section 5 tests AUTOLOAD via the ATTRIBUTE form.
# This section tests the DECLARATIVE form: use Sub::Abstract qw(AUTOLOAD).
# When the abstract AUTOLOAD wrapper is installed, any undefined method
# call on a non-implementing object reaches the wrapper via Perl's
# AUTOLOAD dispatch mechanism.
# ===================================================================

subtest 'declarative AUTOLOAD: undefined method reaches the abstract AUTOLOAD wrapper' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	diag 'ET::DeclAutoloadBase uses declarative "use Sub::Abstract qw(AUTOLOAD)"' if $ENV{TEST_VERBOSE};

	# Any undefined method call on the base triggers AUTOLOAD (the abstract wrapper)
	throws_ok { ET::DeclAutoloadBase->new->any_undefined_method }
		qr/AUTOLOAD\(\) is an abstract method of ET::DeclAutoloadBase/,
		'declarative AUTOLOAD: undefined-method call reaches the abstract wrapper';

	# Subclass with a concrete AUTOLOAD: MRO finds it before the abstract one
	lives_ok { ET::DeclAutoloadImpl->new->any_undefined_method }
		'declarative AUTOLOAD: subclass with concrete AUTOLOAD is not blocked';
};

# ===================================================================
# SECTION 9: Single-underscore method name '_'
#
# The documented validation regex is /\A[_a-zA-Z]\w*\z/.
# A single underscore '_' is a legal Perl identifier (starts with _,
# the \w* part matches zero characters).  This boundary case is not
# exercised by any other test file.
# ===================================================================

subtest 'import() accepts single-underscore method name "_"' => sub {
	plan tests => 2;

	# A fresh package for the single-underscore abstract method
	{ package ET::SingleUnderscore; sub new { bless {}, shift } }

	# import() must not croak for a name that matches the documented regex
	lives_ok {
		package ET::SingleUnderscore;
		Sub::Abstract->import($config{single_underscore});
	} 'import("_") lives: single underscore is a valid Perl identifier';

	# The abstract wrapper must now be installed and fire when called
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	throws_ok { ET::SingleUnderscore->new->_() }
		qr/_\(\) is an abstract method of ET::SingleUnderscore/,
		'"_" abstract wrapper installed and fires with correct message';
};

# ===================================================================
# SECTION 10: Deeply nested package as abstract owner
#
# Verifies that the FULL package name (ET::A::B::C::D::Deep) appears
# in the error message, not just the leaf component ("Deep").
# ===================================================================

subtest 'deeply nested package: full package name in the error message' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	diag "Abstract owner: $config{deep_pkg}" if $ENV{TEST_VERBOSE};

	# The fully-qualified owner name must appear in the croak message
	throws_ok { ET::A::B::C::D::Deep->new->deep_op }
		qr/deep_op\(\) is an abstract method of ET::A::B::C::D::Deep/,
		'deeply nested package: full package name in error message';

	# The implementing subclass must still satisfy the contract
	lives_ok { ET::A::B::C::D::DeepImpl->new->deep_op }
		'deeply nested package: implementing subclass works correctly';
};

# ===================================================================
# SECTION 11: harness_bypass set to a truthy non-1 value
#
# The bypass condition is: $config{harness_bypass} && $ENV{HARNESS_ACTIVE}
# Any truthy value for harness_bypass (not just 1) must enable the bypass.
# Testing with 2 exercises the boolean evaluation of a non-1 truthy integer.
# ===================================================================

subtest 'harness_bypass=2 (truthy non-1): HARNESS_ACTIVE bypass still active' => sub {
	plan tests => 1;

	# Build the wrapper while bypassed so the guard does not fire
	my $wrapper;
	{ local $Sub::Abstract::BYPASS = 1;
	  $wrapper = Sub::Abstract::_wrap('ET::Base', 'render'); }

	# Set harness_bypass to 2 -- truthy, so the bypass must activate
	local $Sub::Abstract::BYPASS                 = 0;
	local $Sub::Abstract::config{harness_bypass} = $config{harness_bypass_hi};
	local $ENV{HARNESS_ACTIVE}                   = 1;

	lives_ok { $wrapper->() }
		"harness_bypass=$config{harness_bypass_hi} + HARNESS_ACTIVE=1: enforcement suppressed";
};

# ===================================================================
# SECTION 12: Unblessed GLOB reference as invocant
#
# ref(\*STDOUT) = 'GLOB'; the invocant lookup uses ref() || $_[0],
# so an unblessed GLOB ref produces the string 'GLOB' in the error.
# edge_cases.t section 4 covers ARRAY and CODE refs; GLOB is distinct.
# ===================================================================

subtest 'GLOB ref as invocant: error message names "GLOB"' => sub {
	plan tests => 1;

	# Build a wrapper directly so we can pass any value as $_[0]
	my $wrapper;
	{ local $Sub::Abstract::BYPASS = 1;
	  $wrapper = Sub::Abstract::_wrap('ET::Base', 'render'); }

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# An unblessed GLOB ref: ref(\*STDOUT) = 'GLOB'
	throws_ok { $wrapper->(\*STDOUT) }
		qr/must be implemented by $config{glob_invocant}/,
		'GLOB ref as $_[0]: invocant reported as "GLOB" in the error';
};

# ===================================================================
# SECTION 13: Extra arguments beyond the invocant
#
# The wrapper only reads $_[0] to identify the invocant.  Passing extra
# arguments must not change the croak message, not modify @_, and not
# clobber $_.
# ===================================================================

subtest 'abstract wrapper: extra arguments beyond the invocant do not affect the croak' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# Call with several extra arguments; only the invocant matters
	throws_ok {
		ET::NoImpl->new->render(
			$config{extra_arg_1}, $config{extra_arg_2}, {key => 'val'}, [1, 2, 3]
		)
	} qr/render\(\) is an abstract method of ET::Base and must be implemented by ET::NoImpl/,
		'extra args: croak message is unaffected by additional arguments';

	# $_ must survive the croak regardless of the arg count
	local $_ = 'preserved';
	eval {
		ET::NoImpl->new->render(
			$config{extra_arg_1}, $config{extra_arg_2}, 'extra3'
		)
	};
	is $_, 'preserved', 'extra args: $_ is preserved after the abstract croak';
};

# ===================================================================
# SECTION 14: import() with 'import' as the abstract method name
#
# 'import' is a valid Perl identifier and commonly used method name.
# Wrapping it as abstract installs the croak-stub in the package's
# 'import' slot; calling the package's import() then croaks.
# This also verifies that Sub::Abstract's own import() is unaffected.
# ===================================================================

subtest 'import() with "import" as the abstract method name' => sub {
	plan tests => 2;

	# Post-CHECK wrap: install an abstract wrapper in ET::SelfImport::import
	{ package ET::SelfImport;
	  sub new { bless {}, shift }
	  Sub::Abstract->import($config{special_import});
	}

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# Calling ET::SelfImport->import() now hits the abstract wrapper
	throws_ok { ET::SelfImport->import() }
		qr/import\(\) is an abstract method of ET::SelfImport/,
		'"import" declared abstract: calling it on the package croaks';

	# Sub::Abstract's own import() must remain unaffected by the above
	my $result = Sub::Abstract->import();
	is $result, $SA,
		'Sub::Abstract->import() still returns the class name after ET::SelfImport wrapping';
};

done_testing;
