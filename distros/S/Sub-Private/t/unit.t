#!/usr/bin/perl
# t/unit.t -- black-box unit tests derived strictly from the POD documentation.
#
# Only the public interface is exercised: import(), the :Private attribute,
# the $BYPASS flag, and the %config hash.  Internal helpers are NOT called
# directly.  Test::Mockingbird is used to isolate public behaviour from
# external dependencies and to force every documented conditional branch.

use strict;
use warnings;

use Test::Most;
use Scalar::Util qw(reftype);
use Readonly;

# enforce mode so runtime wrapper checks fire.
BEGIN { $Sub::Private::config{mode} = 'enforce' }
use Sub::Private;

# Optional helpers; the test suite degrades gracefully if absent.
my $have_returns     = eval { require Test::Returns; Test::Returns->import; 1 };
my $have_mockingbird = eval { require Test::Mockingbird; Test::Mockingbird->import; 1 };

# -------------------------------------------------------------------
# Constants
# -------------------------------------------------------------------

Readonly::Scalar my $SP         => 'Sub::Private';
Readonly::Scalar my $ATTR_OWNER => 'UT::AttrOwner';
Readonly::Scalar my $DECL_OWNER => 'UT::DeclOwner';

# Test parameters collected in one place to avoid magic strings.
my %config = (
	attr_result    => 'attr_secret',
	decl_result    => 'decl_secret',
	invalid_digit  => '123bad',
	invalid_hyphen => 'has-hyphen',
	invalid_empty  => q{},
	documented_ver => '0.05',
);

# -------------------------------------------------------------------
# Package fixtures
# -------------------------------------------------------------------

# Owner class using the :Private attribute form.
{
	package UT::AttrOwner;
	use Sub::Private;

	sub new           { bless {}, shift }
	sub _attr_secret  :Private { 'attr_secret' }
	sub call_secret   { (shift)->_attr_secret }
}

# Subclass: must be BLOCKED even though it inherits from the owner.
{
	package UT::AttrChild;
	our @ISA = ('UT::AttrOwner');
	sub new        { bless {}, shift }
	sub try_secret { (shift)->_attr_secret }
}

# Unrelated stranger: always blocked.
{
	package UT::AttrStranger;
	sub new   { bless {}, shift }
	sub probe { UT::AttrOwner->new->_attr_secret }
}

# Owner class using the declarative form.
{
	package UT::DeclOwner;
	use Sub::Private qw(_decl_secret);

	sub new          { bless {}, shift }
	sub _decl_secret { 'decl_secret' }
	sub call_secret  { (shift)->_decl_secret }
}

# Stranger for the declarative owner.
{
	package UT::DeclStranger;
	sub new   { bless {}, shift }
	sub probe { UT::DeclOwner->new->_decl_secret }
}

# Multiple declarative wraps in one import() call.
{
	package UT::MultiDecl;
	use Sub::Private qw(_alpha _beta);

	sub new       { bless {}, shift }
	sub _alpha    { 'alpha' }
	sub _beta     { 'beta'  }
	sub get_alpha { (shift)->_alpha }
	sub get_beta  { (shift)->_beta  }
}

# Fixture for the set_return spy test.
{
	package UT::SetReturnSpy;
	sub _spy_sub { 'spy' }
}

diag "Black-box unit tests for $SP" if $ENV{TEST_VERBOSE};

# ===================================================================
# SECTION 1: import() with no arguments
# ===================================================================

# POD: "With no arguments: makes the :Private attribute globally available
# via UNIVERSAL.  No other action is taken."
# POD Returns: "The class name ('Sub::Private') as a plain string in all cases."
subtest 'import(): no-args returns the class name' => sub {
	plan tests => $have_returns ? 2 : 1;

	my $result = Sub::Private->import();
	is $result, $SP, 'import() returns the class name';
	returns_ok($result, { type => 'string' }, 'return satisfies string schema')
		if $have_returns;
};

# ===================================================================
# SECTION 2: import() identifier validation
# ===================================================================

# POD: "Each must be a defined, non-reference scalar matching
#  /\A[_a-zA-Z]\w*\z/.  undef, references, empty strings, and names
#  starting with a digit or containing hyphens are all rejected."

# Identifiers starting with a digit are not valid Perl sub names.
subtest 'import(): rejects identifier starting with a digit' => sub {
	plan tests => 2;

	my $bad = $config{invalid_digit};
	throws_ok {
		Sub::Private->import($bad)
	} qr/\Q$SP\E->import: '\Q$bad\E' is not a valid Perl identifier/,
		'digit-start identifier croaks with exact documented message';

	my $err;
	eval { Sub::Private->import($bad) };
	$err = $@;
	like $err, qr/is not a valid Perl identifier/, 'error contains required phrase';
};

# Hyphens are not allowed in Perl identifiers.
subtest 'import(): rejects identifier containing a hyphen' => sub {
	plan tests => 1;

	my $bad = $config{invalid_hyphen};
	throws_ok {
		Sub::Private->import($bad)
	} qr/\Q$SP\E->import: '\Q$bad\E' is not a valid Perl identifier/,
		'hyphen-containing identifier croaks with exact documented message';
};

# Empty string is not a valid sub name.
subtest 'import(): rejects empty-string identifier' => sub {
	plan tests => 1;
	throws_ok { Sub::Private->import($config{invalid_empty}) }
		qr/is not a valid Perl identifier/, 'empty-string identifier croaks';
};

# POD explicitly names undef as a rejected value.
subtest 'import(): undef sub name is rejected with documented error' => sub {
	plan tests => 1;
	throws_ok { Sub::Private->import(undef) }
		qr/is not a valid Perl identifier/,
		'import(undef) croaks with "not a valid Perl identifier"';
};

# POD explicitly names references as rejected values.
subtest 'import(): reference in sub name list is rejected' => sub {
	plan tests => 1;
	throws_ok { Sub::Private->import([]) }
		qr/is not a valid Perl identifier/,
		'import(arrayref) croaks with "not a valid Perl identifier"';
};

# ===================================================================
# SECTION 3: import() with non-existent sub
# ===================================================================

# POD MESSAGES: "Sub::Private: PKG::NAME is not defined"
# "The named sub was not found in the stash at wrap time."
subtest 'import(): croaks with documented message for non-existent sub' => sub {
	plan tests => 2;
	local $Sub::Private::BYPASS = 1;

	my $nonexistent = '_no_such_sub_xyz';
	throws_ok {
		package UT::AttrOwner;
		Sub::Private->import($nonexistent);
	} qr/\Q$SP\E: \Q$ATTR_OWNER\E::\Q$nonexistent\E is not defined/,
		'non-existent sub croaks with exact documented message';

	my $err;
	{ local $Sub::Private::BYPASS = 1;
	  eval { package UT::AttrOwner; Sub::Private->import($nonexistent); };
	  $err = $@; }
	like $err, qr/is not defined/, 'error contains "is not defined"';
};

# ===================================================================
# SECTION 4: import() with namespace mode
# ===================================================================

# POD MESSAGES: "Sub::Private->import: declarative form requires mode => 'enforce'"
# "use Sub::Private qw(...) was called while $config{mode} is not 'enforce'."
subtest 'import(): declarative form with namespace mode croaks' => sub {
	plan tests => 2;
	local $Sub::Private::config{mode} = 'namespace';

	throws_ok { Sub::Private->import('_any') }
		qr/declarative form requires mode => 'enforce'/,
		'declarative form with namespace mode produces documented error';

	# Exact documented message format.
	throws_ok { Sub::Private->import('_any') }
		qr/\Q$SP\E->import: declarative form requires mode => 'enforce'/,
		'exact documented error message for namespace mode';
};

# ===================================================================
# SECTION 5: import() return value in all call forms
# ===================================================================

# POD Returns: "The class name ('Sub::Private') as a plain string in all cases."
# "all cases" means both the no-args form AND the declarative form.

subtest 'import(): declarative form also returns the class name' => sub {
	plan tests => $have_returns ? 2 : 1;
	diag 'Testing declarative import() return value' if $ENV{TEST_VERBOSE};

	# A fresh package with a sub to wrap.
	{ package UT::ReturnCheck; sub _ret_sub { 1 } }
	local $Sub::Private::BYPASS = 1;

	my $result;
	{ package UT::ReturnCheck; $result = Sub::Private->import('_ret_sub'); }

	is $result, $SP, 'declarative import() returns the class name';
	returns_ok($result, { type => 'string' }, 'declarative return satisfies string schema')
		if $have_returns;
};

# ===================================================================
# SECTION 6: import() fail-fast all-or-nothing validation
# ===================================================================

# POD code comment: "Validate every name before touching the stash
# (fail-fast, all-or-nothing)."  If any name is invalid, nothing gets wrapped.

subtest 'import(): fail-fast -- no partial wrapping when any name is invalid' => sub {
	plan tests => 2;

	# _failfast_good comes BEFORE the invalid name, so it passes validation
	# but should still NOT be wrapped (the all-or-nothing guarantee).
	{ package UT::FailFast; sub _failfast_good { 'good' } }

	throws_ok {
		package UT::FailFast;
		Sub::Private->import('_failfast_good', $config{invalid_digit});
	} qr/is not a valid Perl identifier/,
		'import() croaks when any name in the list is invalid';

	# If _failfast_good were wrapped, a stranger call would be blocked.
	# Since nothing was wrapped (all-or-nothing), the stranger call must succeed.
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;
	lives_ok {
		package UT::FailFastChecker;
		UT::FailFast::_failfast_good();
	} '_failfast_good NOT wrapped (fail-fast: no partial wrapping applied)';
};

# ===================================================================
# SECTION 7: :Private attribute form
# ===================================================================

# Owner can call its own private sub.
subtest 'attribute form: owner can call a private sub' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	my $result;
	lives_ok { $result = UT::AttrOwner->new->call_secret }
		'attribute form: owner allowed';
	is $result, $config{attr_result}, 'correct return value';
};

# POD: "Subclasses do not inherit access: private means this package only."
subtest 'attribute form: subclass is BLOCKED when calling from subclass context' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	throws_ok { UT::AttrChild->new->try_secret }
		qr/private subroutine/,
		'attribute form: subclass blocked (private = owner only, no isa chain)';
};

# Unrelated package is blocked.
subtest 'attribute form: unrelated package is blocked' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	throws_ok { UT::AttrStranger->new->probe }
		qr/private subroutine/, 'attribute form: stranger blocked';
};

# ===================================================================
# SECTION 8: Declarative form
# ===================================================================

# Owner can call its own declarative private sub.
subtest 'declarative form: owner can call a private sub' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	my $result;
	lives_ok { $result = UT::DeclOwner->new->call_secret }
		'declarative form: owner allowed';
	is $result, $config{decl_result}, 'correct return value';
};

# Stranger is blocked from declarative private sub.
subtest 'declarative form: unrelated package is blocked' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	throws_ok { UT::DeclStranger->new->probe }
		qr/private subroutine/, 'declarative form: stranger blocked';
};

# Multiple sub names in one import() call are all wrapped independently.
subtest 'declarative form: multiple sub names wrapped in one import()' => sub {
	plan tests => 4;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	my ($ra, $rb);
	lives_ok { $ra = UT::MultiDecl->new->get_alpha } 'owner: _alpha accessible';
	lives_ok { $rb = UT::MultiDecl->new->get_beta  } 'owner: _beta accessible';

	throws_ok { UT::MultiDecl::_alpha(UT::MultiDecl->new) }
		qr/private subroutine/, 'stranger: _alpha blocked';
	throws_ok { UT::MultiDecl::_beta(UT::MultiDecl->new) }
		qr/private subroutine/, 'stranger: _beta blocked';
};

# ===================================================================
# SECTION 9: Error message format
# ===================================================================

# POD: "bar() is a private subroutine of Foo and cannot be called from Bar"
subtest 'error message matches the documented format' => sub {
	plan tests => 3;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	my $err;
	eval { UT::AttrStranger->new->probe };
	$err = $@;

	like $err, qr/_attr_secret\(\)/,      'error contains sub name followed by ()';
	like $err, qr/is a private subroutine of \Q$ATTR_OWNER\E/, 'error contains owner';
	like $err, qr/and cannot be called from UT::AttrStranger/, 'error contains caller';

	diag "Actual error: $err" if $ENV{TEST_VERBOSE};
};

# Full structured regex that matches the documented template exactly.
subtest 'error message structure matches documented template' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	throws_ok { UT::AttrStranger->new->probe }
		qr/\w+\(\) is a private subroutine of \w[\w:]* and cannot be called from \w[\w:]*/,
		'error message structure matches "NAME() is a private subroutine of PKG and cannot be called from PKG"';
};

# ===================================================================
# SECTION 10: $BYPASS
# ===================================================================

# POD: "Set to a true value to disable all access checks (enforce mode only)."
subtest '$BYPASS=1 allows call from any package' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 1;

	my $result;
	lives_ok { $result = UT::AttrStranger->new->probe }
		'$BYPASS=1: stranger is allowed';
	is $result, $config{attr_result}, 'correct value returned under BYPASS';
};

# 'local' must restore the old value when the scope exits.
subtest '$BYPASS is restored after local scope exits' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE} = 0;

	{ local $Sub::Private::BYPASS = 1;
	  lives_ok { UT::AttrStranger->new->probe } '$BYPASS=1 active inside scope'; }

	throws_ok { UT::AttrStranger->new->probe }
		qr/private subroutine/, '$BYPASS restored to 0 after scope exits';
};

# ===================================================================
# SECTION 11: HARNESS_ACTIVE and %config{harness_bypass}
# ===================================================================

# POD: "Either condition alone (OR logic) disables all access checks."
subtest 'HARNESS_ACTIVE=1 alone allows call from any package (default)' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}  = 1;
	local $Sub::Private::BYPASS = 0;

	lives_ok { UT::AttrStranger->new->probe }
		'HARNESS_ACTIVE=1 bypasses access checks by default';
};

# POD: "The HARNESS_ACTIVE bypass can be disabled: $Sub::Private::config{harness_bypass} = 0"
subtest 'config{harness_bypass}=0 disables the HARNESS_ACTIVE shortcut' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}                  = 1;
	local $Sub::Private::BYPASS                 = 0;
	local $Sub::Private::config{harness_bypass} = 0;

	throws_ok { UT::AttrStranger->new->probe }
		qr/private subroutine/,
		'harness_bypass=0: HARNESS_ACTIVE no longer bypasses checks';
};

# POD: "$Sub::Private::config{harness_bypass} -- 1 (default)"
subtest 'config{harness_bypass} defaults to 1' => sub {
	plan tests => 1;
	is $Sub::Private::config{harness_bypass}, 1,
		'%config{harness_bypass} default is 1 as documented';
};

# ===================================================================
# SECTION 12: Full 4-combination bypass truth table
# ===================================================================

# POD: "Either condition alone (OR logic) disables all access checks in enforce mode"
# i.e. enforce iff (BYPASS=0 AND HARNESS_ACTIVE=0).

subtest 'bypass OR logic: all four BYPASS x HARNESS_ACTIVE combinations' => sub {
	plan tests => 4;
	diag 'Testing all combinations of BYPASS and HARNESS_ACTIVE' if $ENV{TEST_VERBOSE};

	# (0, 0) -> enforce
	{ local $Sub::Private::BYPASS = 0; local $ENV{HARNESS_ACTIVE} = 0;
	  throws_ok { UT::AttrStranger->new->probe }
		  qr/private subroutine/, 'BYPASS=0, HARNESS_ACTIVE=0: enforced'; }

	# (1, 0) -> bypass via BYPASS
	{ local $Sub::Private::BYPASS = 1; local $ENV{HARNESS_ACTIVE} = 0;
	  lives_ok { UT::AttrStranger->new->probe }
		  'BYPASS=1, HARNESS_ACTIVE=0: allowed by BYPASS'; }

	# (0, 1) -> bypass via HARNESS_ACTIVE
	{ local $Sub::Private::BYPASS = 0; local $ENV{HARNESS_ACTIVE} = 1;
	  lives_ok { UT::AttrStranger->new->probe }
		  'BYPASS=0, HARNESS_ACTIVE=1: allowed by HARNESS_ACTIVE'; }

	# (1, 1) -> bypass (both active simultaneously)
	{ local $Sub::Private::BYPASS = 1; local $ENV{HARNESS_ACTIVE} = 1;
	  lives_ok { UT::AttrStranger->new->probe }
		  'BYPASS=1, HARNESS_ACTIVE=1: allowed (both active)'; }
};

# ===================================================================
# SECTION 13: Documented public variables and configuration defaults
# ===================================================================

# POD: "our $BYPASS = 0"
subtest 'public variable: $BYPASS default value matches documentation' => sub {
	plan tests => 1;
	is $Sub::Private::BYPASS, 0, '$BYPASS starts at 0 as documented';
};

# POD VERSION section: "Version 0.05"
subtest 'module: $VERSION matches documented value' => sub {
	plan tests => 1;
	is $Sub::Private::VERSION, $config{documented_ver},
		"\$VERSION is '$config{documented_ver}' as documented";
};

# POD: "The :Private attribute is installed in UNIVERSAL, which is intentional"
subtest 'side effect: UNIVERSAL::Private attribute handler is installed' => sub {
	plan tests => 1;
	# Check the symbol table directly -- UNIVERSAL->can() would invoke 'can' as a
	# method call on the string 'UNIVERSAL', which doesn't work as expected.
	ok defined &UNIVERSAL::Private,
		'UNIVERSAL::Private is defined (documented side effect of loading the module)';
};

# ===================================================================
# SECTION 14: Additional POD/code consistency checks
# ===================================================================

# POD: "Each must be a defined, non-reference scalar matching /\A[_a-zA-Z]\w*\z/."
# Identifiers starting with underscore or a letter are valid.
subtest 'POD/code: import() accepts leading-underscore identifiers' => sub {
	plan tests => 1;

	lives_ok {
		package UT::LeadingUnderscore;
		sub _valid_name { 1 }
		Sub::Private->import('_valid_name');
	} 'identifier starting with _ is accepted by import()';
};

# POD: "private means this package only" -- subclass gets no access.
subtest 'POD/code: private is strictly owner-only, not owner-or-subclass' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	lives_ok { UT::AttrOwner->new->call_secret }
		'owner can call private sub';
	throws_ok { UT::AttrChild->new->try_secret }
		qr/private subroutine/,
		'subclass CANNOT call private sub (no isa expansion, unlike Sub::Protected)';
};

# ===================================================================
# SECTION 15: Mock-based tests (if Test::Mockingbird available)
# ===================================================================

if ($have_mockingbird) {
	diag 'Test::Mockingbird available -- running mock / spy tests' if $ENV{TEST_VERBOSE};

	# POD MESSAGES table documents the exact error message for invalid identifiers.
	# Mock validate_strict to throw an *unexpected* internal error to verify that
	# import() always converts any validation failure into the documented message
	# format, regardless of what validate_strict says internally.
	subtest 'mock: import() always produces documented error for any validation failure' => sub {
		plan tests => 1;

		my $guard = Test::Mockingbird::mock_scoped(
			'Sub::Private::validate_strict',
			sub { die "UNEXPECTED_INTERNAL_ERROR\n" }
		);

		throws_ok { Sub::Private->import('_looks_valid') }
			qr/\Q$SP\E->import: '_looks_valid' is not a valid Perl identifier/,
			'import() wraps any validate_strict failure with the documented message';
	};

	# POD Returns: "The class name ('Sub::Private') as a plain string in all cases."
	# Spy on set_return to confirm the class name is passed on every code path.
	subtest 'spy: import() passes class name to set_return in all call forms' => sub {
		plan tests => 2;
		diag 'Spying on set_return across no-args and declarative import()' if $ENV{TEST_VERBOSE};

		my $spy = Test::Mockingbird::spy('Sub::Private::set_return');

		# No-args form -- call from current package.
		Sub::Private->import();
		my @calls_after_noargs = $spy->();
		is $calls_after_noargs[-1][1], $SP,
			'no-args form: set_return receives the class name';

		# Declarative form -- must be called from the package that owns the sub
		# so that caller() inside import() returns the right package.
		{ package UT::SetReturnSpy; Sub::Private->import('_spy_sub'); }
		my @calls_after_decl = $spy->();
		is $calls_after_decl[-1][1], $SP,
			'declarative form: set_return receives the class name';

		Test::Mockingbird::restore_all();
	};

	# Verify that import() calls validate_strict for each name in the list.
	# This confirms the validation is not short-circuited.
	subtest 'spy: import() calls validate_strict once per sub name' => sub {
		plan tests => 1;

		my $spy = Test::Mockingbird::spy('Sub::Private::validate_strict');

		{
			package UT::ValidateSpy;
			sub _a { 1 }
			sub _b { 2 }
			sub _c { 3 }
			Sub::Private->import('_a', '_b', '_c');
		}

		my @calls = $spy->();
		# Three sub names → validate_strict must have been called at least 3 times.
		ok scalar(@calls) >= 3,
			'validate_strict called at least once per sub name in the list';

		Test::Mockingbird::restore_all();
	};
}

done_testing;
