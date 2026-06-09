#!/usr/bin/perl
# t/function.t -- white-box function-level subtests for Sub::Protected
#
# Tests each function individually, mocking non-core dependencies
# (Params::Get, Params::Validate::Strict, Return::Set) where appropriate.
# Uses Test::Returns to verify return-value schema compliance, and
# Test::Memory::Cycle to verify closures leave no circular references.

use strict;
use warnings;

# Non-CPAN test dependencies are sourced from local working trees.
# The BEGIN block untaints $ENV{HOME} so the paths survive prove -lt.
BEGIN {
	my ($home) = ($ENV{HOME} =~ /\A(.+)\z/ms);
	unshift @INC, 'lib',
		"$home/src/njh/Test-Mockingbird/lib",
		"$home/src/njh/Test-Returns/lib";
}

use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Test::Memory::Cycle;
use Scalar::Util qw(reftype);
use Readonly;

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

subtest 'import(): spies confirm get_params and validate_strict are called' => sub {
	plan tests => 2;

	# Spy on Sub::Protected's imported aliases (same reason as set_return above)
	my $spy_gp = spy 'Sub::Protected::get_params';
	my $spy_vs = spy 'Sub::Protected::validate_strict';

	# Define and wrap a new sub so the full validation path is exercised
	{
		package FT::SpyTarget;
		sub _spy_sub { 'spied' }
		Sub::Protected->import('_spy_sub');
	}

	my @gp_calls = $spy_gp->();
	my @vs_calls = $spy_vs->();

	ok scalar(@gp_calls) >= 1, 'get_params invoked during import() with sub names';
	ok scalar(@vs_calls) >= 1, 'validate_strict invoked during import() with sub names';

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
	# call_secret is in FT::Owner; _secret should see FT::Owner as its caller.
	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	lives_ok { FT::Owner->new->call_secret }
		'attribute handler: protected sub callable through owner public method';
};

done_testing;
