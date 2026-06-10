#!/usr/bin/perl
# t/unit.t -- black-box unit tests for Sub::Protected's public API
#
# Every test is derived strictly from the POD documentation.
# No private functions are called directly; only the documented public
# interface is exercised: import(), the :Protected attribute, $BYPASS,
# and %config.
#
# Mocks are used to:
#   * control the environment ($ENV{HARNESS_ACTIVE})
#   * verify that documented external dependencies are invoked
#   * force specific error paths by replacing validation behaviour

use strict;
use warnings;

# Untaint $HOME so prove -lt is happy with the local lib paths
BEGIN {
	my ($home) = ($ENV{HOME} =~ /\A(.+)\z/ms);
	unshift @INC, 'lib',
		"$home/src/njh/Test-Mockingbird/lib",
		"$home/src/njh/Test-Returns/lib";
}

use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Readonly;
use Scalar::Util qw(reftype);

# Loading the module fires CHECK, wrapping all :Protected and declarative
# subs defined in this file's package blocks (see fixtures below).
use Sub::Protected;

# -------------------------------------------------------------------
# Constants and configuration -- no magic strings
# -------------------------------------------------------------------

Readonly::Scalar my $SP          => 'Sub::Protected';
Readonly::Scalar my $ATTR_OWNER  => 'UT::AttrOwner';
Readonly::Scalar my $DECL_OWNER  => 'UT::DeclOwner';
Readonly::Scalar my $PC_OWNER    => 'UT::PostCheck';

# Test configuration (Object::Configure-compatible layout)
my %config = (
	attr_result    => 'attr_secret',
	decl_result    => 'decl_secret',
	pc_result      => 'pc_secret',
	invalid_digit  => '123bad',
	invalid_hyphen => 'has-hyphen',
	invalid_empty  => q{},
);

# -------------------------------------------------------------------
# Package fixtures -- defined at compile time so :Protected and
# declarative wrapping happen at CHECK time, exactly as documented.
# -------------------------------------------------------------------

# Attribute form: sub _attr_secret :Protected is wrapped at CHECK.
{
	package UT::AttrOwner;
	use Sub::Protected;

	sub new          { bless {}, shift }
	sub _attr_secret :Protected { 'attr_secret' }
	sub call_secret  { (shift)->_attr_secret }    # owner-context entry point
}

{
	package UT::AttrChild;
	our @ISA = ('UT::AttrOwner');
	sub new { bless {}, shift }
}

{
	package UT::AttrStranger;
	sub new   { bless {}, shift }
	sub probe { UT::AttrOwner->new->_attr_secret }
}

# Declarative form: _decl_secret is scheduled pre-CHECK via import().
{
	package UT::DeclOwner;
	use Sub::Protected qw(_decl_secret);

	sub new          { bless {}, shift }
	sub _decl_secret { 'decl_secret' }
	sub call_secret  { (shift)->_decl_secret }
}

{
	package UT::DeclChild;
	our @ISA = ('UT::DeclOwner');
	sub new { bless {}, shift }
}

{
	package UT::DeclStranger;
	sub new   { bless {}, shift }
	sub probe { UT::DeclOwner->new->_decl_secret }
}

# Package for post-CHECK wrapping tests; _pc_secret is NOT yet wrapped here.
{
	package UT::PostCheck;

	sub new        { bless {}, shift }
	sub _pc_secret { 'pc_secret' }
	sub call_pc    { (shift)->_pc_secret }
}

{
	package UT::PCStranger;
	sub new   { bless {}, shift }
	sub probe { UT::PostCheck->new->_pc_secret }
}

# Package for multiple-names declarative test
{
	package UT::MultiDecl;
	use Sub::Protected qw(_alpha _beta);

	sub new    { bless {}, shift }
	sub _alpha { 'alpha' }
	sub _beta  { 'beta'  }
	sub get_alpha { (shift)->_alpha }
	sub get_beta  { (shift)->_beta  }
}

{
	package UT::MultiStranger;
	sub new      { bless {}, shift }
	sub try_alpha { UT::MultiDecl->new->_alpha }
	sub try_beta  { UT::MultiDecl->new->_beta  }
}

diag "Black-box unit tests for $SP" if $ENV{TEST_VERBOSE};

# ===================================================================
# SECTION 1: import() with no arguments
#
# POD: "With no arguments: does nothing beyond making the :Protected
#       attribute globally available.  Returns $class."
# ===================================================================

subtest 'import(): no-args returns the class name' => sub {
	plan tests => 2;

	# The return value must be the class name as a string (supports chaining)
	my $result = Sub::Protected->import();
	is $result, $SP, 'import() returns the class name';
	returns_ok($result, { type => 'string' }, 'return value satisfies string schema');
};

subtest 'import(): no-args return value is backed by set_return' => sub {
	plan tests => 2;

	# Spy on the imported set_return alias to confirm it is invoked.
	# (use return::Set qw(set_return) installs an alias in Sub::Protected's namespace)
	my $spy = spy 'Sub::Protected::set_return';

	my $result = Sub::Protected->import();

	my @calls = $spy->();
	is scalar(@calls), 1, 'set_return called exactly once for no-args';
	is $calls[0][1], $SP, 'set_return receives the class name as first value arg';

	restore_all();
};

subtest 'import(): no-args does not wrap any existing sub' => sub {
	plan tests => 1;

	# A sub defined after a plain "use Sub::Protected" must NOT be wrapped.
	# UT::AttrOwner::call_secret is a regular (non-protected) sub; calling it
	# from an unrelated package must succeed regardless of access controls.
	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	my $result;
	lives_ok { $result = UT::AttrOwner->new->call_secret }
		'public method on owner package is unaffected by no-args import()';
};

# ===================================================================
# SECTION 2: import() identifier validation
#
# POD MESSAGES table: "Sub::Protected->import: 'NAME' is not a valid
#   Perl identifier" -- croaks when the name fails /\A[_a-zA-Z]\w*\z/.
# ===================================================================

subtest 'import(): rejects identifier starting with a digit' => sub {
	plan tests => 2;

	my $bad = $config{invalid_digit};
	throws_ok {
		Sub::Protected->import($bad)
	} qr/\Q$SP\E->import: '\Q$bad\E' is not a valid Perl identifier/,
		'digit-start identifier croaks with exact documented message';

	# Verify the regex anchor in the error -- the name is quoted as-is
	my $err;
	eval { Sub::Protected->import($bad) };
	$err = $@;
	like $err, qr/is not a valid Perl identifier/, 'error contains required phrase';
};

subtest 'import(): rejects identifier containing a hyphen' => sub {
	plan tests => 1;

	my $bad = $config{invalid_hyphen};
	throws_ok {
		Sub::Protected->import($bad)
	} qr/\Q$SP\E->import: '\Q$bad\E' is not a valid Perl identifier/,
		'hyphen-containing identifier croaks with exact documented message';
};

subtest 'import(): rejects empty-string identifier' => sub {
	plan tests => 1;

	throws_ok {
		Sub::Protected->import($config{invalid_empty})
	} qr/is not a valid Perl identifier/,
		'empty-string identifier croaks';
};

subtest 'import(): validate_strict failure triggers the documented croak' => sub {
	plan tests => 1;

	# Mock validate_strict to throw unconditionally, simulating any
	# schema mismatch.  The documented behaviour is that import() then
	# croaks with "is not a valid Perl identifier".
	my $g = mock_scoped 'Sub::Protected::validate_strict' =>
		sub { die "forced validation failure\n" };

	# Even a syntactically valid name must be rejected when validation fails
	throws_ok {
		package UT::AttrOwner;
		Sub::Protected->import('_looks_valid');
	} qr/is not a valid Perl identifier/,
		'import() re-croaks the documented message on any validate_strict failure';
};

# ===================================================================
# SECTION 3: import() with a non-existent sub
#
# POD MESSAGES table: "Sub::Protected: PKG::NAME is not defined"
# ===================================================================

subtest 'import(): croaks with documented message for non-existent sub' => sub {
	plan tests => 2;

	local $Sub::Protected::BYPASS = 1;    # bypass the private-caller guard

	my $nonexistent = '_no_such_sub_xyz';

	throws_ok {
		package UT::AttrOwner;
		Sub::Protected->import($nonexistent);
	} qr/\Q$SP\E: \Q$ATTR_OWNER\E::\Q$nonexistent\E is not defined/,
		'non-existent sub croaks with exact documented message';

	my $err;
	{
		local $Sub::Protected::BYPASS = 1;
		eval {
			package UT::AttrOwner;
			Sub::Protected->import($nonexistent);
		};
		$err = $@;
	}
	like $err, qr/is not defined/, 'error contains "is not defined"';
};

# ===================================================================
# SECTION 4: import() with valid sub names (post-CHECK wrapping)
#
# POD: "If the module has already passed CHECK ... wrapping occurs
#       immediately."
# ===================================================================

subtest 'import(): post-CHECK wrapping enforces access control' => sub {
	plan tests => 4;

	# Wrap _pc_secret in UT::PostCheck now (post-CHECK, immediate wrapping).
	# The import() call must come from within UT::PostCheck so that caller()
	# inside import() returns UT::PostCheck as the owner package.
	{
		package UT::PostCheck;
		Sub::Protected->import('_pc_secret');
	}

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# Owner context: must be allowed
	my $result;
	lives_ok {
		$result = UT::PostCheck->new->call_pc;
	} 'import post-CHECK: owner can call wrapped sub';
	is $result, $config{pc_result}, 'wrapped sub returns correct value';

	# Subclass: must be allowed (UT::PCStranger has no ISA, so use AttrChild)
	lives_ok {
		UT::AttrChild->new->call_secret;
	} 'subclass can still call parent attribute-form protected sub';

	# Stranger: must be blocked
	throws_ok { UT::PCStranger->new->probe }
		qr/protected method/,
		'import post-CHECK: stranger is blocked';
};

subtest 'import(): post-CHECK returns the class name' => sub {
	plan tests => 2;

	{
		package UT::AnotherPkg;
		sub _any { 1 }
	}

	my $result;
	{
		package UT::AnotherPkg;
		$result = Sub::Protected->import('_any');
	}

	is $result, $SP, 'import() returns class name when given sub names';
	returns_ok($result, { type => 'string' }, 'return satisfies string schema');
};

# ===================================================================
# SECTION 5: :Protected attribute form (compile-time wrapping)
#
# POD: "The sub is wrapped at CHECK time."
# ===================================================================

subtest 'attribute form: owner can call a protected sub' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	my $result;
	lives_ok { $result = UT::AttrOwner->new->call_secret }
		'attribute form: owner allowed';
	is $result, $config{attr_result}, 'correct return value';
};

subtest 'attribute form: subclass can call inherited protected sub' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# UT::AttrChild isa UT::AttrOwner -- access must be granted
	lives_ok { UT::AttrChild->new->call_secret }
		'attribute form: subclass allowed';
};

subtest 'attribute form: unrelated package is blocked' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	throws_ok { UT::AttrStranger->new->probe }
		qr/protected method/,
		'attribute form: stranger blocked';
};

# ===================================================================
# SECTION 6: Declarative form (compile-time, pre-CHECK wrapping)
#
# POD: "Each named sub is looked up in the caller's stash and wrapped
#       at CHECK time."
# ===================================================================

subtest 'declarative form: owner can call a protected sub' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	my $result;
	lives_ok { $result = UT::DeclOwner->new->call_secret }
		'declarative form: owner allowed';
	is $result, $config{decl_result}, 'correct return value';
};

subtest 'declarative form: subclass can call inherited protected sub' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	lives_ok { UT::DeclChild->new->call_secret }
		'declarative form: subclass allowed';
};

subtest 'declarative form: unrelated package is blocked' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	throws_ok { UT::DeclStranger->new->probe }
		qr/protected method/,
		'declarative form: stranger blocked';
};

subtest 'declarative form: multiple sub names wrapped in one import()' => sub {
	plan tests => 4;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# UT::MultiDecl has _alpha and _beta both declared protected
	my ($ra, $rb);
	lives_ok { $ra = UT::MultiDecl->new->get_alpha } 'owner: _alpha accessible';
	lives_ok { $rb = UT::MultiDecl->new->get_beta  } 'owner: _beta accessible';

	# Both must be independently blocked from outside
	throws_ok { UT::MultiStranger->new->try_alpha }
		qr/protected method/, 'stranger: _alpha blocked';
	throws_ok { UT::MultiStranger->new->try_beta  }
		qr/protected method/, 'stranger: _beta blocked';
};

# ===================================================================
# SECTION 7: Error message format
#
# POD says the format is:
#   "_helper() is a protected method of Foo and cannot be called from Bar"
# ===================================================================

subtest 'error message matches the documented format exactly' => sub {
	plan tests => 3;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	my $err;
	eval { UT::AttrStranger->new->probe };
	$err = $@;

	# Verify each required component of the documented error format
	like $err, qr/_attr_secret\(\)/,
		'error contains sub name followed by ()';
	like $err, qr/is a protected method of \Q$ATTR_OWNER\E/,
		'error contains "is a protected method of" + owner package';
	like $err, qr/and cannot be called from UT::AttrStranger/,
		'error contains "and cannot be called from" + caller package';

	diag "Actual error message: $err" if $ENV{TEST_VERBOSE};
};

# ===================================================================
# SECTION 8: $BYPASS public variable
#
# POD: "Either condition alone (OR logic) disables all access checks:
#       * $Sub::Protected::BYPASS set to a true value."
# ===================================================================

subtest '$BYPASS=1 allows call from any package' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 1;

	my $result;
	lives_ok { $result = UT::AttrStranger->new->probe }
		'$BYPASS=1: stranger is allowed';
	is $result, $config{attr_result}, 'correct value returned under BYPASS';
};

subtest '$BYPASS is restored after local scope exits' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE} = 0;

	{
		local $Sub::Protected::BYPASS = 1;
		lives_ok { UT::AttrStranger->new->probe }
			'$BYPASS=1 active inside scope';
	}

	# After the scope exits, BYPASS must be 0 again
	throws_ok { UT::AttrStranger->new->probe }
		qr/protected method/,
		'$BYPASS restored to 0 after scope exits';
};

# ===================================================================
# SECTION 9: $ENV{HARNESS_ACTIVE} and %config{harness_bypass}
#
# POD: "$ENV{HARNESS_ACTIVE} set (the convention used by Test::Harness)
#       ... The HARNESS_ACTIVE bypass can be disabled by setting:
#       $Sub::Protected::config{harness_bypass} = 0;"
# ===================================================================

subtest 'HARNESS_ACTIVE=1 allows call from any package (default behaviour)' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}    = 1;
	local $Sub::Protected::BYPASS = 0;

	# harness_bypass is 1 by default, so HARNESS_ACTIVE should bypass checks
	lives_ok { UT::AttrStranger->new->probe }
		'HARNESS_ACTIVE=1 bypasses access checks by default';
};

subtest 'config{harness_bypass}=0 disables the HARNESS_ACTIVE shortcut' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}              = 1;
	local $Sub::Protected::BYPASS           = 0;
	local $Sub::Protected::config{harness_bypass} = 0;

	# With harness_bypass disabled, even HARNESS_ACTIVE=1 must not bypass
	throws_ok { UT::AttrStranger->new->probe }
		qr/protected method/,
		'harness_bypass=0: HARNESS_ACTIVE no longer bypasses checks';
};

subtest 'config{harness_bypass} defaults to 1' => sub {
	plan tests => 1;

	is $Sub::Protected::config{harness_bypass}, 1,
		'%config{harness_bypass} default is 1 as documented';
};

# ===================================================================
# SECTION 10: POD/code consistency
#
# Cross-reference documented behaviour against actual behaviour.
# Any discrepancy discovered here should be treated as a documentation
# bug (fix the POD) or a code bug (fix the code), not a test error.
# ===================================================================

subtest 'POD/code: $BYPASS default value matches documentation' => sub {
	plan tests => 1;

	# POD says BYPASS starts false; code initialises it to 0.
	is $Sub::Protected::BYPASS, 0, '$BYPASS starts at 0 as documented';
};

subtest 'POD/code: error message format matches documented template' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# The documented template is:
	#   "NAME() is a protected method of PKG and cannot be called from CALLER"
	throws_ok { UT::AttrStranger->new->probe }
		qr/\w+\(\) is a protected method of \w[\w:]* and cannot be called from \w[\w:]*/,
		'error message structure matches the documented template';
};

subtest 'POD/code: import() accepts leading-underscore identifiers' => sub {
	plan tests => 1;

	# The POD documents the regex /\A[_a-zA-Z]\w*\z/, which allows a leading
	# underscore.  Confirm that _-prefixed names are accepted (not rejected).
	lives_ok {
		package UT::LeadingUnderscore;
		sub _valid_name { 1 }
		Sub::Protected->import('_valid_name');
	} 'identifier starting with _ is accepted by import()';
};

subtest 'POD/code: documented identity of BYPASS or HARNESS_ACTIVE (OR logic)' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# Confirm stranger IS blocked when both are off (the base case)
	throws_ok { UT::AttrStranger->new->probe }
		qr/protected method/,
		'both bypass mechanisms off: access enforced';

	# Either one alone must be sufficient to bypass
	{
		local $Sub::Protected::BYPASS = 1;
		lives_ok { UT::AttrStranger->new->probe }
			'BYPASS alone (HARNESS_ACTIVE=0) is sufficient to bypass';
	}
};

# ===================================================================
# SECTION 11: import() with undef sub name
#
# Regression test for the bug where undef bypassed validate_strict and
# reached _process_one, producing "is not defined" instead of the
# documented "is not a valid Perl identifier" message.
# ===================================================================

subtest 'import(): undef sub name is rejected with documented error' => sub {
	plan tests => 1;

	# Must croak with the identifier-validation message, not a downstream error.
	throws_ok { Sub::Protected->import(undef) }
		qr/is not a valid Perl identifier/,
		'import(undef) croaks with "not a valid Perl identifier"';
};

done_testing;
