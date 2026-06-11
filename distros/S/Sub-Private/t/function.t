#!/usr/bin/perl
# t/function.t -- white-box function-level tests for Sub::Private
#
# Tests every internal helper and public entry point in isolation.
# Where Test::Mockingbird is available, non-core dependencies are spied
# on or mocked so each function is exercised on its own behaviour.

use strict;
use warnings;

use Test::Most;
use Scalar::Util qw(reftype);
use Readonly;

# Set enforce mode before loading so attribute-form fixtures use it.
# The CHECK block fires immediately after compilation; mode must be set first.
BEGIN { $Sub::Private::config{mode} = 'enforce' }
use Sub::Private;

# Optional test helpers -- loaded with eval so the suite degrades gracefully.
my $have_mockingbird = eval { require Test::Mockingbird; Test::Mockingbird->import; 1 };
my $have_returns     = eval { require Test::Returns; Test::Returns->import; 1 };
my $have_cycle       = eval { require Test::Memory::Cycle; Test::Memory::Cycle->import; 1 };

# -------------------------------------------------------------------
# Constants -- avoid magic strings throughout the test file
# -------------------------------------------------------------------

Readonly::Scalar my $SP       => 'Sub::Private';
Readonly::Scalar my $OWNER    => 'FT::Owner';
Readonly::Scalar my $CHILD    => 'FT::Child';
Readonly::Scalar my $STRANGER => 'FT::Stranger';
Readonly::Scalar my $CHK_PKG  => 'FT::CheckOwner';
Readonly::Scalar my $CHK_SUB  => 'chk_fn';

# Configuration hash for test parameters.
my %config = (
	valid_sub        => '_secret',
	proc_sub         => '_proc_target',
	nonexistent_sub  => '_ft_nonexistent_xyz',
	invalid_digit    => '123bad',
	invalid_hyphen   => 'has-hyphen',
	invalid_empty    => q{},
	secret_result    => 'secret',
	proc_result      => 'proc',
);

# -------------------------------------------------------------------
# Package fixtures
# -------------------------------------------------------------------

# Primary owner fixture with a :Private sub and public accessors.
{
	package FT::Owner;
	use Sub::Private;

	sub new             { bless {}, shift }
	sub _secret         :Private { 'secret' }
	sub _bare_unwrapped { 'bare' }
	sub _proc_target    { 'proc' }
	sub call_secret     { (shift)->_secret }
	sub call_fn         { my (undef, $fn) = @_; $fn->() }
}

# Subclass: must be BLOCKED from calling its parent's private sub.
{
	package FT::Child;
	our @ISA = ('FT::Owner');
	sub new        { bless {}, shift }
	sub try_secret { (shift)->_secret }
}

# Unrelated stranger: must always be blocked.
{
	package FT::Stranger;
	sub new   { bless {}, shift }
	sub probe { FT::Owner->new->_secret }
}

# Fixtures for direct _check_access() call-site testing.
{
	package FT::CheckOwner;
	sub call_check { Sub::Private::_check_access('FT::CheckOwner', 'chk_fn') }
}

{
	package FT::CheckChild;
	our @ISA = ('FT::CheckOwner');
	sub call_check { Sub::Private::_check_access('FT::CheckOwner', 'chk_fn') }
}

{
	package FT::CheckStranger;
	sub call_check { Sub::Private::_check_access('FT::CheckOwner', 'chk_fn') }
}

# Fixture for _assert_private_caller() -- external caller must be rejected.
# try_assert calls _assert_private_caller directly; caller(1) there is whoever
# called try_assert (i.e. the test code in main).
{
	package FT::External;
	sub try_assert { Sub::Private::_assert_private_caller('_test_method') }
}

# Fixture that simulates the real usage pattern: a guarded function calls
# _assert_private_caller so that caller(1) inside the guard is the package
# of whoever called the guarded function -- here FT::ExternalGuarded.
{
	package FT::ExternalGuarded;
	sub guarded_fn  { Sub::Private::_assert_private_caller('guarded_fn') }
	sub call_guarded { FT::ExternalGuarded::guarded_fn() }
}

# Two-level chain inside Sub::Private's own namespace (enables the allow path).
{
	package Sub::Private;
	sub _ft_inner_assert { Sub::Private::_assert_private_caller('_ft_inner_assert') }
	sub _ft_outer_assert { Sub::Private::_ft_inner_assert() }
}

# Post-CHECK declarative wrapping fixture.
{
	package FT::ImportTarget;
	sub _importable { 'importable' }
	Sub::Private->import('_importable');
}

# Caller-transparency fixture: private sub reports caller(0)'s package.
# With goto &$code the wrapper frame is invisible, so we should see
# FT::CallerCheck (the run() frame) rather than Sub::Private.
{
	package FT::CallerCheck;
	use Sub::Private;
	sub new            { bless {}, shift }
	sub _report_caller :Private { (caller(0))[0] }
	sub run            { (shift)->_report_caller }
}

# Fresh package for _process_one() spy test to avoid double-wrapping.
{
	package FT::ProcessSpy;
	sub new          { bless {}, shift }
	sub _spy_target  { 'spy_target' }
}

diag "Starting white-box function tests for $SP" if $ENV{TEST_VERBOSE};

# ===================================================================
# SECTION 1: import()
# ===================================================================

# No arguments: attribute form only, returns class name.
subtest 'import(): no-args returns the class name' => sub {
	plan tests => $have_returns ? 2 : 1;
	diag 'Testing no-argument import() return value' if $ENV{TEST_VERBOSE};

	my $result = Sub::Private->import();
	is $result, $SP, 'import() returns the class name';
	returns_ok($result, { type => 'string' }, 'return value satisfies string schema')
		if $have_returns;
};

# Identifier starting with a digit is not a valid Perl sub name.
subtest 'import(): rejects identifier starting with a digit' => sub {
	plan tests => 2;

	throws_ok { Sub::Private->import($config{invalid_digit}) }
		qr/is not a valid Perl identifier/,
		'digit-start identifier croaks';
	# Exact message format includes module name and the offending identifier.
	throws_ok { Sub::Private->import($config{invalid_digit}) }
		qr/\Q$SP\E->import: '\Q$config{invalid_digit}\E' is not a valid Perl identifier/,
		'exact error message for digit-start identifier';
};

# Hyphens are not allowed in Perl identifiers.
subtest 'import(): rejects identifier containing a hyphen' => sub {
	plan tests => 1;
	throws_ok { Sub::Private->import($config{invalid_hyphen}) }
		qr/is not a valid Perl identifier/,
		'hyphen identifier croaks';
};

# Empty string is not a valid sub name.
subtest 'import(): rejects empty-string identifier' => sub {
	plan tests => 1;
	throws_ok { Sub::Private->import($config{invalid_empty}) }
		qr/is not a valid Perl identifier/,
		'empty string croaks';
};

# undef in the import list should be coerced to empty string and rejected.
subtest 'import(): rejects undef in the sub name list' => sub {
	plan tests => 1;
	throws_ok { Sub::Private->import(undef) }
		qr/is not a valid Perl identifier/,
		'undef in import list croaks';
};

# A reference (e.g. arrayref) is not a valid sub name.
subtest 'import(): rejects a reference in the sub name list' => sub {
	plan tests => 1;
	throws_ok { Sub::Private->import([]) }
		qr/is not a valid Perl identifier/,
		'arrayref in import list croaks';
};

# Declarative form is only allowed in enforce mode.
subtest 'import(): croaks when mode is namespace and sub names are given' => sub {
	plan tests => 2;
	local $Sub::Private::config{mode} = 'namespace';

	throws_ok { Sub::Private->import('_some_sub') }
		qr/declarative form requires mode => 'enforce'/,
		'import() croaks in namespace mode with sub names';
	throws_ok { Sub::Private->import('_some_sub') }
		qr/\Q$SP\E->import: declarative form requires mode => 'enforce'/,
		'exact error message for namespace-mode declarative call';
};

# Post-CHECK path: sub does not exist in the stash at wrap time.
subtest 'import(): croaks for non-existent sub (post-CHECK path)' => sub {
	plan tests => 1;
	local $Sub::Private::BYPASS = 1;
	throws_ok {
		package FT::ImportCroak;
		Sub::Private->import($config{nonexistent_sub});
	} qr/\Q$config{nonexistent_sub}\E is not defined/,
		'import() croaks when the named sub does not exist';
};

# Wrapped sub must allow owner and block strangers.
subtest 'import(): wrapped sub enforces access (post-CHECK)' => sub {
	plan tests => 3;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	my $result;
	lives_ok {
		package FT::ImportTarget;
		$result = FT::ImportTarget::_importable();
	} 'import: owner can call wrapped sub';
	is $result, 'importable', 'correct return value from wrapped sub';

	throws_ok {
		package FT::ImportStranger;
		FT::ImportTarget::_importable();
	} qr/private subroutine/,
		'import: unrelated package blocked from wrapped sub';
};

# $_ must not be clobbered on either the happy path or the croak path.
subtest 'import(): does not clobber $_' => sub {
	plan tests => 2;

	# Happy path (no-args).
	{ local $_ = 'preserve_me';
	  Sub::Private->import();
	  is $_, 'preserve_me', 'import() no-args did not clobber $_'; }

	# Croak path (invalid identifier).
	{ local $_ = 'preserve_me';
	  eval { Sub::Private->import($config{invalid_digit}) };
	  is $_, 'preserve_me', 'import() croak path did not clobber $_'; }
};

# ===================================================================
# SECTION 2: _wrap()
# ===================================================================

# Guard must reject external callers even from test code.
subtest '_wrap(): private guard blocks call from outside Sub::Private' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	throws_ok {
		Sub::Private::_wrap($OWNER, '_bare_unwrapped', sub { 1 })
	} qr/_wrap\(\) is a private method of \Q$SP\E/,
		'_wrap() croaks when called directly from outside Sub::Private';
	# Exact format: includes "cannot be called from <caller>".
	throws_ok {
		Sub::Private::_wrap($OWNER, '_bare_unwrapped', sub { 1 })
	} qr/_wrap\(\) is a private method of \Q$SP\E and cannot be called from main/,
		'_wrap() croak message names the offending caller package';
};

# BYPASS=1 skips the guard entirely; a CODE ref must be returned.
subtest '_wrap(): BYPASS=1 skips guard and returns a CODE ref' => sub {
	plan tests => 2;
	local $Sub::Private::BYPASS = 1;
	diag 'Testing _wrap() with BYPASS=1' if $ENV{TEST_VERBOSE};

	my $wrapper;
	lives_ok {
		$wrapper = Sub::Private::_wrap($OWNER, '_bare_unwrapped', sub { 42 });
	} '_wrap() lives when BYPASS=1';
	ok defined($wrapper) && reftype($wrapper) eq 'CODE', '_wrap() returns a CODE ref';
};

# HARNESS_ACTIVE alone (with harness_bypass=1) also skips the guard.
subtest '_wrap(): HARNESS_ACTIVE=1 skips guard and returns a CODE ref' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}  = 1;
	local $Sub::Private::BYPASS = 0;

	my $wrapper;
	lives_ok {
		$wrapper = Sub::Private::_wrap($OWNER, '_bare_unwrapped', sub { 99 });
	} '_wrap() lives when HARNESS_ACTIVE=1';
	ok defined($wrapper) && reftype($wrapper) eq 'CODE', '_wrap() returns CODE ref';
};

# Returned closure must allow calls originating from the owner package.
subtest '_wrap(): returned closure allows call from owner package' => sub {
	plan tests => 2;

	my $wrapper;
	{ local $Sub::Private::BYPASS = 1;
	  $wrapper = Sub::Private::_wrap($OWNER, '_bare_unwrapped', sub { 'allowed' }); }

	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	my $result;
	lives_ok { $result = FT::Owner->new->call_fn($wrapper) }
		'wrapper allows call via FT::Owner::call_fn';
	is $result, 'allowed', 'wrapper returns the original coderef result';
};

# Returned closure must block calls from unrelated packages.
subtest '_wrap(): returned closure blocks call from unrelated package' => sub {
	plan tests => 1;

	my $wrapper;
	{ local $Sub::Private::BYPASS = 1;
	  $wrapper = Sub::Private::_wrap($OWNER, '_bare_unwrapped', sub { 1 }); }

	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	throws_ok {
		package FT::WrapBlockTest;
		$wrapper->();
	} qr/_bare_unwrapped\(\) is a private subroutine of \Q$OWNER\E/,
		'wrapper blocks call from unrelated package';
};

# Closure must be free of circular references so the GC can collect it.
subtest '_wrap(): returned closure has no circular references' => sub {
	plan tests => 1;
	SKIP: {
		skip 'Test::Memory::Cycle not available', 1 unless $have_cycle;

		local $Sub::Private::BYPASS = 1;
		my $wrapper = Sub::Private::_wrap($OWNER, '_bare_unwrapped', sub { 42 });
		memory_cycle_ok($wrapper, 'wrapper closure has no circular references');
	}
};

# _wrap() must not clobber $_ on either path.
subtest '_wrap(): does not clobber $_' => sub {
	plan tests => 2;

	# Guard-fires path.
	{ local $_ = 'preserve_me';
	  local $ENV{HARNESS_ACTIVE}  = 0;
	  local $Sub::Private::BYPASS = 0;
	  eval { Sub::Private::_wrap($OWNER, '_bare_unwrapped', sub { 1 }) };
	  is $_, 'preserve_me', '_wrap() guard path did not clobber $_'; }

	# Normal path.
	{ local $_ = 'preserve_me';
	  local $Sub::Private::BYPASS = 1;
	  Sub::Private::_wrap($OWNER, '_bare_unwrapped', sub { 1 });
	  is $_, 'preserve_me', '_wrap() normal path did not clobber $_'; }
};

# ===================================================================
# SECTION 3: _check_access()
# ===================================================================

subtest '_check_access(): allows call from the owner package' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	lives_ok { FT::CheckOwner::call_check() }
		'_check_access() returns normally for the owner package';
};

# Private != protected: subclasses are blocked with no isa check.
subtest '_check_access(): BLOCKS call from a subclass' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	throws_ok { FT::CheckChild::call_check() }
		qr/private subroutine/,
		'_check_access() blocks subclass (no isa allowance)';
};

# Canonical error message format must be produced for outsiders.
subtest '_check_access(): blocks outsider with canonical error message' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	my $expected = qr/\Q$CHK_SUB\E\(\) is a private subroutine of \Q$CHK_PKG\E and cannot be called from FT::CheckStranger/;
	throws_ok { FT::CheckStranger::call_check() } $expected,
		'_check_access() croaks with canonical message format';

	my $err;
	eval { FT::CheckStranger::call_check() };
	$err = $@;
	like $err, qr/cannot be called from/, 'error contains "cannot be called from"';
};

# BYPASS=1 alone is sufficient to skip all enforcement.
subtest '_check_access(): BYPASS=1 short-circuits all checks' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 1;

	lives_ok { FT::CheckStranger::call_check() }
		'_check_access() short-circuits when BYPASS=1';
};

# HARNESS_ACTIVE=1 alone (with harness_bypass=1) is also sufficient.
subtest '_check_access(): HARNESS_ACTIVE=1 short-circuits all checks' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}  = 1;
	local $Sub::Private::BYPASS = 0;

	lives_ok { FT::CheckStranger::call_check() }
		'_check_access() short-circuits when HARNESS_ACTIVE=1';
};

# When harness_bypass=0, HARNESS_ACTIVE must NOT bypass enforcement.
subtest '_check_access(): harness_bypass=0 suppresses HARNESS_ACTIVE bypass' => sub {
	plan tests => 2;
	local $Sub::Private::config{harness_bypass} = 0;
	local $ENV{HARNESS_ACTIVE}                  = 1;
	local $Sub::Private::BYPASS                 = 0;

	lives_ok { FT::CheckOwner::call_check() }
		'_check_access() still allows owner when harness_bypass=0';

	throws_ok { FT::CheckStranger::call_check() }
		qr/private subroutine/,
		'_check_access() blocks stranger when harness_bypass=0 + HARNESS_ACTIVE=1';
};

# $_ must not be clobbered on the croak path.
subtest '_check_access(): does not clobber $_' => sub {
	plan tests => 1;
	local $_ = 'preserve_me';
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;
	eval { FT::CheckStranger::call_check() };
	is $_, 'preserve_me', '_check_access() did not clobber $_ on croak path';
};

# ===================================================================
# SECTION 4: _process_one()
# ===================================================================

# External callers must be rejected by the private guard.
subtest '_process_one(): private guard blocks call from outside Sub::Private' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	throws_ok {
		Sub::Private::_process_one($OWNER, $config{proc_sub})
	} qr/_process_one\(\) is a private method of \Q$SP\E/,
		'_process_one() croaks when called from main';
};

# If the named sub does not exist, _process_one() must croak with exact message.
subtest '_process_one(): croaks when the named sub is not defined' => sub {
	plan tests => 2;
	local $Sub::Private::BYPASS = 1;

	throws_ok {
		Sub::Private::_process_one('FT::NoPkg', $config{nonexistent_sub})
	} qr/\Q$config{nonexistent_sub}\E is not defined/,
		'_process_one() croaks for an undefined sub';

	# Full error includes module name and the fully-qualified sub reference.
	throws_ok {
		Sub::Private::_process_one('FT::NoPkg', $config{nonexistent_sub})
	} qr/\Q$SP\E: FT::NoPkg::\Q$config{nonexistent_sub}\E is not defined/,
		'exact error message includes module name and qualified sub name';
};

# After a successful call the stash entry must be replaced with a wrapper.
subtest '_process_one(): installs a wrapper coderef in the stash' => sub {
	plan tests => 3;

	my $original = \&FT::Owner::_proc_target;
	{ local $Sub::Private::BYPASS = 1;
	  Sub::Private::_process_one($OWNER, $config{proc_sub}); }

	my $wrapped = \&FT::Owner::_proc_target;
	isnt $wrapped, $original, '_process_one() replaced the stash entry';
	ok defined($wrapped) && reftype($wrapped) eq 'CODE', 'replacement is a CODE ref';

	# The installed wrapper must allow calls from the owner package.
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;
	lives_ok {
		FT::Owner->new->call_fn(\&FT::Owner::_proc_target);
	} '_process_one: owner can call the wrapped sub via call_fn';
};

# ===================================================================
# SECTION 5: _assert_private_caller()
# ===================================================================

# Must croak with a descriptive message when called from outside Sub::Private.
subtest '_assert_private_caller(): croaks when caller is not Sub::Private' => sub {
	plan tests => 3;

	throws_ok { FT::External::try_assert() }
		qr/_test_method\(\) is a private method of \Q$SP\E and cannot be called from/,
		'_assert_private_caller() croaks from non-Sub::Private context';

	# Use the guarded-function fixture to verify that caller(1) reports the
	# package of whoever called the guarded function (FT::ExternalGuarded here).
	throws_ok { FT::ExternalGuarded::call_guarded() }
		qr/guarded_fn\(\) is a private method of \Q$SP\E and cannot be called from FT::ExternalGuarded/,
		'_assert_private_caller() error names the external caller package';

	my $err;
	eval { FT::External::try_assert() };
	$err = $@;
	like $err, qr/is a private method of \Q$SP\E/, 'error contains expected phrase';
};

# Must return normally when the caller is Sub::Private itself.
subtest '_assert_private_caller(): allows when caller is Sub::Private' => sub {
	plan tests => 1;

	lives_ok { Sub::Private::_ft_outer_assert() }
		'_assert_private_caller() returns normally in a Sub::Private call chain';
};

# $_ must not be clobbered on the croak path.
subtest '_assert_private_caller(): does not clobber $_' => sub {
	plan tests => 1;
	local $_ = 'preserve_me';
	eval { FT::External::try_assert() };
	is $_, 'preserve_me', '_assert_private_caller() did not clobber $_ on croak path';
};

# ===================================================================
# SECTION 6: Attribute handler (ATTR(CODE,CHECK))
# ===================================================================

# The handler should wrap the sub and enforce access at runtime.
subtest 'attribute handler: wraps sub and enforces access' => sub {
	plan tests => 3;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	my $result;
	lives_ok { $result = FT::Owner->new->call_secret }
		'attribute handler: owner can call its private sub';
	is $result, $config{secret_result}, 'private sub returns correct value';

	throws_ok { FT::Stranger->new->probe }
		qr/_secret\(\) is a private subroutine of \Q$OWNER\E/,
		'attribute handler: stranger blocked with canonical message';
};

# Subclass context must be blocked -- private is owner-only.
subtest 'attribute handler: subclass is BLOCKED' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	throws_ok { FT::Child->new->try_secret }
		qr/private subroutine/,
		'attribute handler: subclass blocked (no isa allowance)';
};

# ===================================================================
# SECTION 7: harness_bypass=0 -- guards fire even with HARNESS_ACTIVE=1
# ===================================================================

# When harness_bypass=0, HARNESS_ACTIVE must not suppress the _wrap guard.
subtest '_wrap(): guard fires when harness_bypass=0 and HARNESS_ACTIVE=1' => sub {
	plan tests => 1;
	local $Sub::Private::config{harness_bypass} = 0;
	local $ENV{HARNESS_ACTIVE}                  = 1;
	local $Sub::Private::BYPASS                 = 0;

	throws_ok {
		Sub::Private::_wrap($OWNER, '_bare_unwrapped', sub { 1 });
	} qr/_wrap\(\) is a private method of \Q$SP\E/,
		'_wrap() guard fires when harness_bypass=0 and HARNESS_ACTIVE=1';
};

# Same property for _process_one.
subtest '_process_one(): guard fires when harness_bypass=0 and HARNESS_ACTIVE=1' => sub {
	plan tests => 1;
	local $Sub::Private::config{harness_bypass} = 0;
	local $ENV{HARNESS_ACTIVE}                  = 1;
	local $Sub::Private::BYPASS                 = 0;

	throws_ok {
		Sub::Private::_process_one($OWNER, $config{proc_sub});
	} qr/_process_one\(\) is a private method of \Q$SP\E/,
		'_process_one() guard fires when harness_bypass=0 and HARNESS_ACTIVE=1';
};

# ===================================================================
# SECTION 8: _assert_known_mode()
# ===================================================================

# The two valid mode strings must be accepted without error.
subtest '_assert_known_mode(): accepts namespace' => sub {
	plan tests => 1;
	lives_ok { Sub::Private::_assert_known_mode('namespace') }
		'_assert_known_mode() lives for "namespace"';
};

subtest '_assert_known_mode(): accepts enforce' => sub {
	plan tests => 1;
	lives_ok { Sub::Private::_assert_known_mode('enforce') }
		'_assert_known_mode() lives for "enforce"';
};

# Any other value must croak with a descriptive message.
subtest '_assert_known_mode(): croaks for unknown mode' => sub {
	plan tests => 3;

	throws_ok { Sub::Private::_assert_known_mode('typo') }
		qr/unknown mode 'typo'.*use 'namespace' or 'enforce'/s,
		'_assert_known_mode() croaks for unknown value';

	throws_ok { Sub::Private::_assert_known_mode(q{}) }
		qr/unknown mode/,
		'_assert_known_mode() croaks for empty string';

	# Exact message format: "Sub::Private: unknown mode '...' -- use '...' or '...'"
	throws_ok { Sub::Private::_assert_known_mode('bad') }
		qr/\Q$SP\E: unknown mode 'bad' -- use 'namespace' or 'enforce'/,
		'_assert_known_mode() exact error message format';
};

# $_ must not be clobbered on the croak path.
subtest '_assert_known_mode(): does not clobber $_' => sub {
	plan tests => 1;
	local $_ = 'preserve_me';
	eval { Sub::Private::_assert_known_mode('bad') };
	is $_, 'preserve_me', '_assert_known_mode() did not clobber $_ on croak path';
};

# ===================================================================
# SECTION 9: Caller transparency (goto &$code)
# ===================================================================

# The enforce-mode wrapper uses 'goto &$code' to make itself invisible
# to caller() inside the private sub.  This is load-bearing: if it were
# replaced with $code->(@_), caller(0) inside the private sub would
# report Sub::Private instead of the real caller.
subtest 'caller transparency: goto makes wrapper frame invisible' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;
	diag 'Testing goto transparency via FT::CallerCheck::_report_caller' if $ENV{TEST_VERBOSE};

	my $caller_pkg;
	lives_ok { $caller_pkg = FT::CallerCheck->new->run }
		'private sub reports its caller without dying';

	# With goto, caller(0) inside _report_caller sees FT::CallerCheck (run's package),
	# NOT Sub::Private (the package in which the wrapper closure was defined).
	is $caller_pkg, 'FT::CallerCheck',
		'caller(0) inside private sub sees FT::CallerCheck, not Sub::Private';
};

# ===================================================================
# SECTION 10: spy / mock verification (if Test::Mockingbird available)
# ===================================================================

if ($have_mockingbird) {
	diag 'Test::Mockingbird available -- running spy/mock tests' if $ENV{TEST_VERBOSE};

	# import() must call validate_strict once per sub name supplied.
	subtest 'import(): spy confirms validate_strict called per sub name' => sub {
		plan tests => 2;

		my $spy_vs = Test::Mockingbird::spy('Sub::Private::validate_strict');

		{
			package FT::SpyVS;
			sub _sub_a { 'a' }
			sub _sub_b { 'b' }
			Sub::Private->import('_sub_a', '_sub_b');
		}

		my @vs_calls = $spy_vs->();
		ok scalar(@vs_calls) >= 2,
			'validate_strict called at least once per sub name';
		# Each call should receive a 'schema' key -- verify first call structure.
		ok(
			(grep { defined $_ && $_ eq 'schema' } @{$vs_calls[0]}),
			'validate_strict called with schema key'
		);

		Test::Mockingbird::restore_all();
	};

	# import() must call set_return in both the no-args and declarative forms.
	subtest 'import(): spy confirms set_return called' => sub {
		plan tests => 2;
		diag 'Spying on set_return during import()' if $ENV{TEST_VERBOSE};

		my $spy_sr = Test::Mockingbird::spy('Sub::Private::set_return');

		Sub::Private->import();   # no-args form
		my @no_arg_calls = $spy_sr->();
		ok scalar(@no_arg_calls) >= 1,
			'set_return called for no-args import()';

		# Also test declarative form (add another spy call on top).
		{
			package FT::SpySR;
			sub _sr_target { 'sr' }
			Sub::Private->import('_sr_target');
		}
		my @all_calls = $spy_sr->();
		ok scalar(@all_calls) >= 2,
			'set_return called for declarative import() as well';

		Test::Mockingbird::restore_all();
	};

	# _check_access() must call croak exactly once and with the canonical message.
	subtest '_check_access(): spy confirms croak called once for outsider' => sub {
		plan tests => 3;
		local $ENV{HARNESS_ACTIVE}  = 0;
		local $Sub::Private::BYPASS = 0;
		diag 'Spying on croak during _check_access() outsider test' if $ENV{TEST_VERBOSE};

		my $spy_croak = Test::Mockingbird::spy('Sub::Private::croak');
		eval { FT::CheckStranger::call_check() };

		my @calls = $spy_croak->();
		is scalar(@calls), 1, 'croak called exactly once per unauthorised access';
		like $calls[0][1],
			qr/\Q$CHK_SUB\E\(\) is a private subroutine of \Q$CHK_PKG\E/,
			'croak message contains sub name and owner package';
		like $calls[0][1],
			qr/cannot be called from FT::CheckStranger/,
			'croak message names the caller package';

		Test::Mockingbird::restore_all();
	};

	# _assert_known_mode() must call croak with the right message for bad values.
	subtest '_assert_known_mode(): spy confirms croak message for unknown mode' => sub {
		plan tests => 2;

		my $spy_croak = Test::Mockingbird::spy('Sub::Private::croak');
		eval { Sub::Private::_assert_known_mode('bogus') };

		my @calls = $spy_croak->();
		is scalar(@calls), 1, 'croak called exactly once for unknown mode';
		like $calls[0][1],
			qr/unknown mode 'bogus'/,
			'croak message references the bad mode value';

		Test::Mockingbird::restore_all();
	};

	# _process_one() must call _wrap() with the correct owner and sub name.
	subtest '_process_one(): spy confirms _wrap called with correct args' => sub {
		plan tests => 3;

		my $spy_wrap = Test::Mockingbird::spy('Sub::Private::_wrap');
		{ local $Sub::Private::BYPASS = 1;
		  Sub::Private::_process_one('FT::ProcessSpy', '_spy_target'); }

		my @calls = $spy_wrap->();
		is scalar(@calls), 1, '_wrap called exactly once by _process_one';
		is $calls[0][1], 'FT::ProcessSpy', '_wrap called with correct owner_pkg';
		is $calls[0][2], '_spy_target',    '_wrap called with correct sub_name';

		Test::Mockingbird::restore_all();
	};
}

done_testing;
