#!/usr/bin/perl
# t/function.t -- white-box function-level subtests for Sub::Protected
#
# Tests each function individually, mocking non-core dependencies
# (Params::Get, Params::Validate::Strict, Return::Set, B::Hooks::EndOfScope,
# Sub::Identify) where appropriate.
# Uses Test::Returns to verify return-value schema compliance, and
# Test::Memory::Cycle to verify closures leave no circular references.

use strict;
use warnings;

use Test::Most;

# Test::Mockingbird needs Perl 5.16.3, so it is an optional test dependency
BEGIN {
	eval { require Test::Mockingbird; Test::Mockingbird->import(); 1 }
		or plan(skip_all => 'Test::Mockingbird not installed');
}
use Test::Returns;
use Test::Memory::Cycle;
use Scalar::Util qw(reftype);
use Readonly;

# Load these before anything mocks them: mocking a sub before its module is
# loaded lets the later require overwrite the mock, and restore_all() then
# deletes the real sub
use B::Hooks::EndOfScope ();
use Sub::Identify ();

# Loading Sub::Protected fires the CHECK block and sets $_post_check = 1,
# so any subsequent import() calls with sub names wrap immediately.
use Sub::Protected;

# -------------------------------------------------------------------
# Constants -- no magic strings or numbers anywhere in the file
# -------------------------------------------------------------------

Readonly::Scalar my $SP       => 'Sub::Protected';
Readonly::Scalar my $OWNER    => 'FT::Owner';
Readonly::Scalar my $CHILD    => 'FT::Child';
Readonly::Scalar my $STRANGER => 'FT::Stranger';
Readonly::Scalar my $CHK_PKG  => 'FT::CheckOwner';
Readonly::Scalar my $CHK_SUB  => 'chk_fn';

# Configuration hash -- Object::Configure-compatible layout
my %config = (
	valid_sub        => '_secret',
	proc_sub         => '_proc_target',
	nonexistent_sub  => '_ft_nonexistent_xyz',
	invalid_digit    => '123bad',
	invalid_hyphen   => 'has-hyphen',
	invalid_empty    => q{},
	secret_result    => 'secret',
	proc_result      => 'proc',
	importable_result => 'importable',
);

# -------------------------------------------------------------------
# Package fixtures -- defined at compile time so :Protected wraps
# happen at CHECK phase, before any subtests run.
# -------------------------------------------------------------------

# FT::Owner: the owner package with attribute-form, bare, and proc subs.
{
	package FT::Owner;
	use Sub::Protected;

	sub new             { bless {}, shift }
	sub _secret         :Protected { 'secret' }   # attribute-form protected sub
	sub _bare_unwrapped { 'bare'   }               # not wrapped -- used in _wrap tests
	sub _proc_target    { 'proc'   }               # used in _process_one tests

	# call_secret: public entry point to the protected sub (for testing)
	sub call_secret { (shift)->_secret }

	# _who reports the package that called it; call_who reaches it from FT::Owner
	sub _who :Protected { (caller(0))[0] }
	sub call_who { (shift)->_who }

	# call_fn: generic trampoline -- calls the passed coderef from FT::Owner context.
	# This lets tests invoke a wrapper closure from the correct owner context.
	sub call_fn { my (undef, $fn) = @_; $fn->() }
}

# FT::Child: subclass -- protected calls from here must succeed
{
	package FT::Child;
	our @ISA = ('FT::Owner');
	sub new { bless {}, shift }
}

# FT::Stranger: unrelated package -- all protected calls must fail
{
	package FT::Stranger;
	sub new   { bless {}, shift }
	sub probe { FT::Owner->new->_secret }
}

# -------------------------------------------------------------------
# Fixtures for direct _check_access() testing.
# Each package's call_check() invokes _check_access from that context.
# -------------------------------------------------------------------

{
	package FT::CheckOwner;
	sub call_check { Sub::Protected::_check_access('FT::CheckOwner', 'chk_fn') }
}

{
	package FT::CheckChild;
	our @ISA = ('FT::CheckOwner');
	sub call_check { Sub::Protected::_check_access('FT::CheckOwner', 'chk_fn') }
}

{
	package FT::CheckStranger;
	sub call_check { Sub::Protected::_check_access('FT::CheckOwner', 'chk_fn') }
}

# -------------------------------------------------------------------
# Fixtures for _assert_private_caller() testing.
# -------------------------------------------------------------------

# FT::External: calls _assert_private_caller from a foreign package -- must croak
{
	package FT::External;
	sub try_assert { Sub::Protected::_assert_private_caller('_test_method') }
}

# Two-level chain compiled in Sub::Protected's own namespace.
# Subs declared inside "package Sub::Protected" compile with that package as
# their package, so caller() reports Sub::Protected, enabling the allow path
# in _assert_private_caller without any glob-assignment tricks.
{
	package Sub::Protected;

	# _ft_inner_assert: calls _assert_private_caller directly.  caller(0)
	# inside _assert_private_caller = Sub::Protected (this sub's package).
	sub _ft_inner_assert { Sub::Protected::_assert_private_caller('_ft_inner_assert') }

	# _ft_outer_assert: calls _ft_inner_assert.  caller(1) inside
	# _assert_private_caller = Sub::Protected (this sub's package), which
	# satisfies the $SELF check and lets _assert_private_caller return normally.
	sub _ft_outer_assert { Sub::Protected::_ft_inner_assert() }
}

# -------------------------------------------------------------------
# FT::ImportTarget: sub wrapped via post-CHECK import() call.
# The import() call originates from FT::ImportTarget so that caller()
# inside import() reports FT::ImportTarget as the owner package.
# -------------------------------------------------------------------

{
	package FT::ImportTarget;
	sub _importable { 'importable' }
	Sub::Protected->import('_importable');
}

diag "Starting white-box function tests for $SP" if $ENV{TEST_VERBOSE};

# ===================================================================
# SECTION 1: import()
# ===================================================================

subtest 'import(): no-args returns the class name' => sub {
	plan tests => 3;

	# Spy on Sub::Protected's imported alias, not Return::Set directly.
	# use Return::Set qw(set_return) copies the code ref into Sub::Protected's
	# namespace, so spying on Return::Set::set_return misses those calls.
	my $spy = spy 'Sub::Protected::set_return';

	my $result = Sub::Protected->import();

	# Return must satisfy the string schema and equal the class name
	returns_ok($result, { type => 'string' }, 'import() returns a string');
	is $result, $SP, 'import() returns the class name (supports method chaining)';

	# Verify set_return was invoked exactly once for the no-args path
	my @calls = $spy->();
	is scalar(@calls), 1, 'set_return called exactly once';

	restore_all();
};

subtest 'import(): no-args does not clobber $_' => sub {
	plan tests => 1;

	local $_ = 'fn_import_sentinel';
	Sub::Protected->import();
	is $_, 'fn_import_sentinel', '$_ unchanged after no-args import()';
};

subtest 'import(): rejects identifier starting with a digit' => sub {
	plan tests => 1;

	throws_ok {
		Sub::Protected->import($config{invalid_digit})
	} qr/is not a valid Perl identifier/,
		'digit-start identifier croaks with correct message';
};

subtest 'import(): rejects identifier containing a hyphen' => sub {
	plan tests => 1;

	throws_ok {
		Sub::Protected->import($config{invalid_hyphen})
	} qr/is not a valid Perl identifier/,
		'hyphen-containing identifier croaks with correct message';
};

subtest 'import(): rejects empty-string identifier' => sub {
	plan tests => 1;

	throws_ok {
		Sub::Protected->import($config{invalid_empty})
	} qr/is not a valid Perl identifier/,
		'empty string croaks with correct message';
};

subtest 'import(): croaks for non-existent sub (post-CHECK path)' => sub {
	plan tests => 1;

	# BYPASS=1 lets _process_one skip its private-caller guard so we can
	# exercise the "sub not defined" croak path from outside Sub::Protected.
	local $Sub::Protected::BYPASS = 1;

	throws_ok {
		package FT::ImportCroak;
		Sub::Protected->import($config{nonexistent_sub});
	} qr/\Q$config{nonexistent_sub}\E is not defined/,
		'import() croaks when the named sub does not exist';

	diag "Tested non-existent-sub croak: $config{nonexistent_sub}" if $ENV{TEST_VERBOSE};
};

subtest 'import(): wrapped sub enforces access (post-CHECK)' => sub {
	plan tests => 3;

	# FT::ImportTarget::_importable was wrapped in the fixtures block above.
	# Disable HARNESS_ACTIVE so the access check actually runs.
	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# Owner (FT::ImportTarget) may call its own wrapped sub
	my $result;
	lives_ok {
		package FT::ImportTarget;
		$result = FT::ImportTarget::_importable();
	} 'import: owner can call wrapped sub';
	is $result, $config{importable_result}, 'correct return value from wrapped sub';

	# Stranger is blocked with the canonical error message
	throws_ok {
		package FT::ImportStranger;
		FT::ImportTarget::_importable();
	} qr/protected method/,
		'import: unrelated package blocked from wrapped sub';
};

subtest 'import(): get_params only for a single reference; validate_strict always' => sub {
	plan tests => 3;

	# Spy on Sub::Protected's imported aliases (same reason as set_return above)
	my $spy_gp = spy 'Sub::Protected::get_params';
	my $spy_vs = spy 'Sub::Protected::validate_strict';

	# A plain list must bypass Params::Get, so qw(subs _x) is never read as
	# subs => '_x'; an arrayref is normalised by it
	{
		package FT::SpyTarget;
		sub _spy_sub  { 'spied' }
		sub _spy_sub2 { 'spied' }
		Sub::Protected->import('_spy_sub');
	}
	my @gp_plain = $spy_gp->();
	{
		package FT::SpyTarget;
		Sub::Protected->import([ '_spy_sub2' ]);
	}
	my @gp_all = $spy_gp->();
	my @vs_calls = $spy_vs->();

	is scalar(@gp_plain), 0, 'get_params not used for a plain list';
	is scalar(@gp_all), 1, 'get_params used for a single arrayref';
	is scalar(@vs_calls), 2, 'validate_strict checks every name';

	restore_all();
};

# ===================================================================
# SECTION 2: _wrap()
# ===================================================================

subtest '_wrap(): private guard blocks call from outside Sub::Protected' => sub {
	plan tests => 1;

	# Both bypass mechanisms must be off so the guard fires
	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	throws_ok {
		Sub::Protected::_wrap($OWNER, '_bare_unwrapped', sub { 1 })
	} qr/_wrap\(\) is a private method of \Q$SP\E/,
		'_wrap() croaks when called directly from main';
};

subtest '_wrap(): BYPASS=1 skips guard and returns a CODE ref' => sub {
	plan tests => 2;

	local $Sub::Protected::BYPASS = 1;

	my $wrapper;
	lives_ok {
		$wrapper = Sub::Protected::_wrap($OWNER, '_bare_unwrapped', sub { 42 });
	} '_wrap() lives when BYPASS=1';

	ok(defined($wrapper) && reftype($wrapper) eq 'CODE',
		'_wrap() returns a CODE ref');
};

subtest '_wrap(): HARNESS_ACTIVE=1 skips guard and returns a CODE ref' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}    = 1;
	local $Sub::Protected::BYPASS = 0;

	my $wrapper;
	lives_ok {
		$wrapper = Sub::Protected::_wrap($OWNER, '_bare_unwrapped', sub { 99 });
	} '_wrap() lives when HARNESS_ACTIVE=1';

	ok(defined($wrapper) && reftype($wrapper) eq 'CODE',
		'_wrap() returns CODE ref when HARNESS_ACTIVE=1');
};

subtest '_wrap(): returned closure allows call from owner package' => sub {
	plan tests => 2;

	# Build the wrapper with bypass on, then test it with bypass off
	my $wrapper;
	{
		local $Sub::Protected::BYPASS = 1;
		$wrapper = Sub::Protected::_wrap($OWNER, '_bare_unwrapped', sub { 'allowed' });
	}

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# FT::Owner::call_fn is compiled in FT::Owner's package, so caller() inside
	# the wrapper sees FT::Owner -- which equals $owner_pkg --> allow.
	my $result;
	lives_ok {
		$result = FT::Owner->new->call_fn($wrapper);
	} 'wrapper allows call via FT::Owner::call_fn';

	is $result, 'allowed', 'wrapper returns the original coderef result';
};

subtest '_wrap(): returned closure blocks call from unrelated package' => sub {
	plan tests => 1;

	my $wrapper;
	{
		local $Sub::Protected::BYPASS = 1;
		$wrapper = Sub::Protected::_wrap($OWNER, '_bare_unwrapped', sub { 1 });
	}

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# package FT::WrapBlockTest is unrelated to FT::Owner -- must be blocked
	throws_ok {
		package FT::WrapBlockTest;
		$wrapper->();
	} qr/_bare_unwrapped\(\) is a protected method of \Q$OWNER\E/,
		'wrapper blocks call from unrelated package';
};

subtest '_wrap(): returned closure does not clobber $_' => sub {
	plan tests => 1;

	my $wrapper;
	{
		local $Sub::Protected::BYPASS = 1;
		$wrapper = Sub::Protected::_wrap($OWNER, '_bare_unwrapped', sub { 'ok' });
	}

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	local $_ = 'wrap_sentinel';
	eval { FT::Owner->new->call_fn($wrapper) };    # success path; $_ must survive
	is $_, 'wrap_sentinel', '$_ not clobbered by wrapper closure or _check_access';
};

subtest '_wrap(): returned closure has no circular references' => sub {
	plan tests => 1;

	local $Sub::Protected::BYPASS = 1;
	my $wrapper = Sub::Protected::_wrap($OWNER, '_bare_unwrapped', sub { 42 });
	memory_cycle_ok($wrapper, 'wrapper closure has no circular references');
};

# ===================================================================
# SECTION 3: _check_access()
# ===================================================================

subtest '_check_access(): allows call from the owner package' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# FT::CheckOwner::call_check invokes _check_access with owner=FT::CheckOwner
	# from FT::CheckOwner context -- the first non-SP frame is the owner itself.
	lives_ok { FT::CheckOwner::call_check() }
		'_check_access() returns normally for the owner package';
};

subtest '_check_access(): allows call from a subclass' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# FT::CheckChild isa FT::CheckOwner, so ->isa check passes
	lives_ok { FT::CheckChild::call_check() }
		'_check_access() returns normally for a subclass';
};

subtest '_check_access(): blocks outsider with canonical error message' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# The spec mandates: "NAME() is a protected method of PKG and cannot be called from CALLER"
	my $expected = qr/\Q$CHK_SUB\E\(\) is a protected method of \Q$CHK_PKG\E and cannot be called from FT::CheckStranger/;

	throws_ok { FT::CheckStranger::call_check() }
		$expected,
		'_check_access() croaks with canonical message format';

	my $err;
	eval { FT::CheckStranger::call_check() };
	$err = $@;
	like $err, qr/cannot be called from/,
		'error message contains "cannot be called from"';
};

subtest '_check_access(): BYPASS=1 short-circuits all checks' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 1;

	# Even a stranger is allowed when BYPASS is set
	lives_ok { FT::CheckStranger::call_check() }
		'_check_access() short-circuits when BYPASS=1';
};

subtest '_check_access(): HARNESS_ACTIVE=1 short-circuits all checks' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}    = 1;
	local $Sub::Protected::BYPASS = 0;

	lives_ok { FT::CheckStranger::call_check() }
		'_check_access() short-circuits when HARNESS_ACTIVE=1';
};

subtest '_check_access(): does not clobber $_' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	local $_ = 'chk_sentinel';
	FT::CheckOwner::call_check();    # must succeed without touching $_
	is $_, 'chk_sentinel', '$_ not clobbered by _check_access()';
};

# ===================================================================
# SECTION 4: _process_one()
# ===================================================================

subtest '_process_one(): private guard blocks call from outside Sub::Protected' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	throws_ok {
		Sub::Protected::_process_one($OWNER, $config{proc_sub})
	} qr/_process_one\(\) is a private method of \Q$SP\E/,
		'_process_one() croaks when called from main';
};

subtest '_process_one(): croaks when the named sub is not defined' => sub {
	plan tests => 1;

	local $Sub::Protected::BYPASS = 1;

	throws_ok {
		Sub::Protected::_process_one('FT::NoPkg', $config{nonexistent_sub})
	} qr/\Q$config{nonexistent_sub}\E is not defined/,
		'_process_one() croaks for an undefined sub';
};

subtest '_process_one(): installs a wrapper coderef in the stash' => sub {
	plan tests => 3;

	# Capture original coderef before wrapping
	my $original = \&FT::Owner::_proc_target;

	{
		local $Sub::Protected::BYPASS = 1;
		Sub::Protected::_process_one($OWNER, $config{proc_sub});
	}

	# The glob slot must now hold a different (wrapper) coderef
	my $wrapped = \&FT::Owner::_proc_target;
	isnt $wrapped, $original,
		'_process_one() replaced the stash entry with a new coderef';
	ok(defined($wrapped) && reftype($wrapped) eq 'CODE',
		'replacement entry is a CODE ref');

	# Verify the wrapped sub still works from the owner context
	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	my $result;
	lives_ok {
		$result = FT::Owner->new->call_fn(\&FT::Owner::_proc_target);
	} '_process_one: owner can call the wrapped sub via call_fn';

	diag "proc_target returned: $result" if $ENV{TEST_VERBOSE};
};

subtest '_process_one(): does not clobber $_' => sub {
	plan tests => 1;

	local $Sub::Protected::BYPASS = 1;

	local $_ = 'proc_sentinel';
	eval { Sub::Protected::_process_one('FT::NoPkg', $config{nonexistent_sub}) };
	# Expected croak; we only care that $_ is intact after the exception
	is $_, 'proc_sentinel', '$_ not clobbered by _process_one()';
};

# ===================================================================
# SECTION 5: _assert_private_caller()
# ===================================================================

subtest '_assert_private_caller(): croaks when caller is not Sub::Protected' => sub {
	plan tests => 2;

	# FT::External::try_assert calls _assert_private_caller directly.
	# Inside _assert_private_caller: caller(1) = main (test body) != Sub::Protected.
	throws_ok { FT::External::try_assert() }
		qr/_test_method\(\) is a private method of \Q$SP\E and cannot be called from/,
		'_assert_private_caller() croaks from non-Sub::Protected context';

	my $err;
	eval { FT::External::try_assert() };
	$err = $@;
	like $err, qr/is a private method of \Q$SP\E/,
		'error message contains "is a private method of Sub::Protected"';
};

subtest '_assert_private_caller(): allows when caller is Sub::Protected' => sub {
	plan tests => 1;

	# _ft_outer_assert (Sub::Protected) calls _ft_inner_assert (Sub::Protected),
	# which calls _assert_private_caller.  caller(1) inside = Sub::Protected -> allow.
	lives_ok { Sub::Protected::_ft_outer_assert() }
		'_assert_private_caller() returns normally within a Sub::Protected call chain';
};

subtest '_assert_private_caller(): does not clobber $_' => sub {
	plan tests => 1;

	local $_ = 'assert_sentinel';
	eval { FT::External::try_assert() };    # expected croak; $_ must survive
	is $_, 'assert_sentinel', '$_ not clobbered by _assert_private_caller()';
};

# ===================================================================
# SECTION 6: UNIVERSAL::Protected attribute handler
# ===================================================================

subtest 'attribute handler: wraps sub and enforces access' => sub {
	plan tests => 3;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# Owner-context call via the public trampoline must succeed
	my $result;
	lives_ok { $result = FT::Owner->new->call_secret }
		'attribute handler: owner can call its protected sub';
	is $result, $config{secret_result}, 'protected sub returns correct value';

	# Stranger is blocked with the canonical error message
	throws_ok { FT::Stranger->new->probe }
		qr/_secret\(\) is a protected method of \Q$OWNER\E/,
		'attribute handler: stranger blocked with canonical message';
};

subtest 'attribute handler: Sub::Protected wrapper is invisible in caller()' => sub {
	plan tests => 1;

	# The goto &$code in the wrapper removes the wrapper frame so that caller()
	# inside the protected sub reports the real caller, not Sub::Protected.
	# call_who is in FT::Owner, so _who must see FT::Owner as its caller.
	# Without the goto it would see Sub::Protected (where the wrapper lives).
	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	is(FT::Owner->new->call_who, $OWNER,
		'caller() inside the protected sub reports the real caller');
};

# ===================================================================
# SECTION 7: harness_bypass=0 -- guards still fire with HARNESS_ACTIVE=1
#
# These tests verify the interaction of %config{harness_bypass} with
# HARNESS_ACTIVE across _check_access, _wrap, and _process_one.
# ===================================================================

subtest '_check_access(): harness_bypass=0 suppresses HARNESS_ACTIVE bypass' => sub {
	plan tests => 2;

	# With harness_bypass=0, HARNESS_ACTIVE=1 must NOT bypass _check_access.
	local $Sub::Protected::config{harness_bypass} = 0;
	local $ENV{HARNESS_ACTIVE}                    = 1;
	local $Sub::Protected::BYPASS                 = 0;

	# Owner (FT::CheckOwner) must still be allowed
	lives_ok { FT::CheckOwner::call_check() }
		'_check_access() still allows owner when harness_bypass=0';

	# Stranger must still be blocked
	throws_ok { FT::CheckStranger::call_check() }
		qr/protected method/,
		'_check_access() still blocks stranger when harness_bypass=0 + HARNESS_ACTIVE=1';
};

subtest '_wrap(): guard fires even with HARNESS_ACTIVE=1 when harness_bypass=0' => sub {
	plan tests => 1;

	local $Sub::Protected::config{harness_bypass} = 0;
	local $ENV{HARNESS_ACTIVE}                    = 1;
	local $Sub::Protected::BYPASS                 = 0;

	# _wrap called from main:: must croak despite HARNESS_ACTIVE=1
	throws_ok {
		Sub::Protected::_wrap($OWNER, '_bare_unwrapped', sub { 1 });
	} qr/_wrap\(\) is a private method of \Q$SP\E/,
		'_wrap() guard fires when harness_bypass=0 and HARNESS_ACTIVE=1';
};

subtest '_process_one(): guard fires even with HARNESS_ACTIVE=1 when harness_bypass=0' => sub {
	plan tests => 1;

	local $Sub::Protected::config{harness_bypass} = 0;
	local $ENV{HARNESS_ACTIVE}                    = 1;
	local $Sub::Protected::BYPASS                 = 0;

	# _process_one called from main:: must croak despite HARNESS_ACTIVE=1
	throws_ok {
		Sub::Protected::_process_one($OWNER, $config{proc_sub});
	} qr/_process_one\(\) is a private method of \Q$SP\E/,
		'_process_one() guard fires when harness_bypass=0 and HARNESS_ACTIVE=1';
};

# ===================================================================
# SECTION 8: _assert_private_caller -- isa() branch
#
# The guard: return if $caller eq $SELF || eval { $caller->isa($SELF) }
# Test that a Sub::Protected subclass passes via the isa() arm.
# ===================================================================

# FT::SP::Sub: a Sub::Protected subclass compiled so caller(1) from inside
# _assert_private_caller reports FT::SP::Sub, and ->isa('Sub::Protected') = true.
{
	package FT::SP::Sub;
	our @ISA = ('Sub::Protected');

	sub _isa_inner { Sub::Protected::_assert_private_caller('_isa_inner') }
	sub _isa_outer { FT::SP::Sub::_isa_inner() }
}

subtest '_assert_private_caller(): allows Sub::Protected subclass (isa branch)' => sub {
	plan tests => 1;

	# Calling via FT::SP::Sub makes caller(1) = FT::SP::Sub inside the guard.
	# FT::SP::Sub->isa('Sub::Protected') is true, so the guard returns normally.
	lives_ok { FT::SP::Sub::_isa_outer() }
		'_assert_private_caller() allows caller that is a Sub::Protected subclass';
};

# ===================================================================
# SECTION 9: UNIVERSAL::Protected BEGIN phase (run-time loading)
#
# The handler is called at BEGIN and at CHECK.  Before CHECK the BEGIN call
# must do nothing (CHECK does the work); after CHECK it must defer wrapping
# to end of scope, because CHECK will never fire again.
# ===================================================================

Readonly::Scalar my $ATTR_NAME => 'Protected';

# Results of calling the handler at BEGIN phase while this file is still
# being compiled, i.e. before CHECK.  Recorded here, asserted in a subtest.
my %pre_check;
{
	package FT::PreCheck;
	sub _early { 'early' }
}
BEGIN {
	my $hooks = 0;
	mock 'B::Hooks::EndOfScope::on_scope_end' => sub { $hooks++ };
	my $before = \&FT::PreCheck::_early;
	my @ret = UNIVERSAL::Protected('FT::PreCheck', \*FT::PreCheck::_early, $before, 'Protected', undef, 'BEGIN');
	restore_all();
	%pre_check = (
		hooks     => $hooks,
		unchanged => (\&FT::PreCheck::_early == $before) ? 1 : 0,
		returned  => scalar(@ret),
	);
}

# Fixtures for driving the handler by hand after CHECK
{
	package FT::Deferred;
	sub _later { 'later' }
	sub call_later { FT::Deferred::_later() }
}
{
	package FT::Direct;
	sub _direct { 'direct' }
	sub call_direct { FT::Direct::_direct() }
}

subtest 'attribute handler: BEGIN phase before CHECK is a no-op' => sub {
	plan tests => 3;

	# Before CHECK the CHECK-phase call does the wrapping, so the BEGIN call
	# must neither register an end-of-scope hook nor touch the sub
	is $pre_check{hooks}, 0, 'no end-of-scope hook registered before CHECK';
	ok $pre_check{unchanged}, 'sub is not wrapped by the BEGIN-phase call';
	is $pre_check{returned}, 0, 'handler returns an empty list';

	diag 'pre-CHECK BEGIN results: ' . join(', ', map { "$_=$pre_check{$_}" } sort keys %pre_check)
		if $ENV{TEST_VERBOSE};
};

subtest 'attribute handler: BEGIN phase after CHECK defers wrapping to end of scope' => sub {
	plan tests => 8;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# Capture the end-of-scope callback instead of letting it run, so we can
	# check that nothing is wrapped until the scope really ends
	my @hooks;
	mock 'B::Hooks::EndOfScope::on_scope_end' => sub { push @hooks, $_[0] };

	# At BEGIN the sub may still be anonymous, so the handler must get the
	# name from Sub::Identify, not from the glob it is passed
	my @identified;
	mock 'Sub::Identify::get_code_info' => sub { push @identified, $_[0]; return ('FT::Deferred', '_later') };

	my $original = \&FT::Deferred::_later;
	my @ret = UNIVERSAL::Protected('FT::Deferred', 'ANON', $original, $ATTR_NAME, undef, 'BEGIN');

	is scalar(@ret), 0, 'handler returns an empty list';
	is scalar(@hooks), 1, 'exactly one end-of-scope hook registered';
	ok \&FT::Deferred::_later == $original, 'sub is not wrapped until the scope ends';

	# Simulate the end of the file being compiled
	$hooks[0]->();
	restore_all();

	is scalar(@identified), 1, 'Sub::Identify consulted once';
	ok $identified[0] == $original, 'Sub::Identify was asked about the decorated sub';
	ok \&FT::Deferred::_later != $original, 'sub is wrapped once the scope ends';
	is(FT::Deferred::call_later(), 'later', 'owner can still call the wrapped sub');
	throws_ok { FT::Deferred::_later() }
		qr/\A_later\(\) is a protected method of FT::Deferred and cannot be called from main at /,
		'unrelated caller is blocked with the exact message';
};

subtest 'attribute handler: CHECK phase wraps the named glob' => sub {
	plan tests => 5;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	my $original = \&FT::Direct::_direct;
	my @ret = UNIVERSAL::Protected('FT::Direct', \*FT::Direct::_direct, $original, $ATTR_NAME, undef, 'CHECK');

	is scalar(@ret), 0, 'handler returns an empty list';
	ok \&FT::Direct::_direct != $original, 'stash entry replaced with the wrapper';
	is(FT::Direct::call_direct(), 'direct', 'owner can call the wrapped sub');
	throws_ok { FT::Direct::_direct() }
		qr/\A_direct\(\) is a protected method of FT::Direct and cannot be called from main at /,
		'unrelated caller is blocked with the exact message';
	memory_cycle_ok(\&FT::Direct::_direct, 'installed wrapper has no circular references');
};

subtest 'attribute handler: sub compiled by string eval after CHECK is protected' => sub {
	plan tests => 3;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# End to end, with the real B::Hooks::EndOfScope and Sub::Identify: the
	# eval is compiled after CHECK, so only the BEGIN-phase path can wrap it
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	my $ok = eval q{
		package FT::Evald;
		sub _evald :Protected { 'evald' }
		sub call_evald { FT::Evald::_evald() }
		1;
	};
	diag "string eval error: $@" if !$ok && $ENV{TEST_VERBOSE};

	is(FT::Evald::call_evald(), 'evald', 'owner can call the protected sub');
	throws_ok { FT::Evald::_evald() }
		qr/\A_evald\(\) is a protected method of FT::Evald and cannot be called from main at /,
		'unrelated caller is blocked';
	is_deeply \@warnings, [], 'no warnings while compiling after CHECK';
};

# ===================================================================
# SECTION 10: import() before CHECK, and the CHECK block
#
# Before CHECK, import() must only queue names; the CHECK block wraps them.
# ===================================================================

# Record the stash entry just before and just after a pre-CHECK import()
my %queued;
{
	package FT::Queued;
	sub _queued { 'queued' }
	sub call_queued { FT::Queued::_queued() }
	BEGIN {
		$queued{before} = \&FT::Queued::_queued;
		$queued{return} = Sub::Protected->import('_queued');
		$queued{after}  = \&FT::Queued::_queued;
	}
}

subtest 'import(): before CHECK queues the sub; the CHECK block wraps it' => sub {
	plan tests => 5;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	ok $queued{after} == $queued{before}, 'import() before CHECK does not wrap immediately';
	is $queued{return}, $SP, 'import() with names returns the class name';
	ok \&FT::Queued::_queued != $queued{before}, 'CHECK block has since wrapped the sub';
	is(FT::Queued::call_queued(), 'queued', 'owner can call the wrapped sub');
	throws_ok { FT::Queued::_queued() }
		qr/\A_queued\(\) is a protected method of FT::Queued and cannot be called from main at /,
		'unrelated caller is blocked';
};

# ===================================================================
# SECTION 11: exact messages, return values and other details
# ===================================================================

# _check_access() when every frame belongs to Sub::Protected.  This must be
# run at file scope: inside a subtest the test framework's frames are found.
my $no_context_error;
{
	package Sub::Protected;
	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;
	$no_context_error = eval { Sub::Protected::_check_access('FT::Nowhere', 'lost'); 1 } ? undef : $@;
}

subtest '_check_access(): croaks when no caller outside Sub::Protected exists' => sub {
	plan tests => 1;

	like $no_context_error,
		qr/\Alost\(\) is a protected method of FT::Nowhere and cannot be called outside any package context at /,
		'croaks with the "outside any package context" message';
};

subtest 'import(): exact error messages for invalid names' => sub {
	plan tests => 2;

	throws_ok { Sub::Protected->import($config{invalid_digit}) }
		qr/\A\Q$SP\E->import: '\Q$config{invalid_digit}\E' is not a valid Perl identifier at /,
		'invalid name is quoted in the message';

	# undef must be rejected, not slip through as a valid "string"
	throws_ok { Sub::Protected->import(undef) }
		qr/\A\Q$SP\E->import: '' is not a valid Perl identifier at /,
		'undef is rejected as an empty name';
};

subtest 'import(): with names returns the class name and keeps $_' => sub {
	plan tests => 2;

	{
		package FT::ImportReturn;
		sub _ret { 'ret' }
	}

	local $_ = 'import_names_sentinel';
	my $result;
	{
		package FT::ImportReturn;
		$result = Sub::Protected->import('_ret');
	}
	returns_ok($result, { type => 'string' }, 'import() with names returns a string');
	is $_, 'import_names_sentinel', '$_ unchanged after import() with names';
};

subtest '_wrap(): return value is a CODE ref' => sub {
	plan tests => 1;

	local $Sub::Protected::BYPASS = 1;
	returns_ok(Sub::Protected::_wrap($OWNER, '_bare_unwrapped', sub { 1 }), { type => 'coderef' },
		'_wrap() returns a coderef');
};

subtest '_process_one(): returns an empty list' => sub {
	plan tests => 1;

	{
		package FT::ProcReturn;
		sub _pr { 'pr' }
	}
	local $Sub::Protected::BYPASS = 1;
	my @ret = Sub::Protected::_process_one('FT::ProcReturn', '_pr');
	is scalar(@ret), 0, '_process_one() returns nothing';
};

subtest 'private guards: exact error messages' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	throws_ok { Sub::Protected::_wrap($OWNER, '_bare_unwrapped', sub { 1 }) }
		qr/\A_wrap\(\) is a private method of \Q$SP\E and cannot be called from main at /,
		'_wrap() guard names the method, the module and the caller';
	throws_ok { Sub::Protected::_process_one($OWNER, $config{proc_sub}) }
		qr/\A_process_one\(\) is a private method of \Q$SP\E and cannot be called from main at /,
		'_process_one() guard names the method, the module and the caller';
};

subtest 'attribute handler: installed wrapper has no circular references' => sub {
	plan tests => 1;

	memory_cycle_ok(\&FT::Owner::_secret, 'wrapper installed at CHECK has no circular references');
};

done_testing;
