#!/usr/bin/perl
# t/extended_tests.t -- coverage-boosting tests targeting previously untested paths
#
# Specifically targets:
#   - harness_bypass=0 disables HARNESS_ACTIVE for all three guarded functions
#   - Sub::Protected subclass allowed by _assert_private_caller (the isa() branch)
#   - Truthy and falsy sweep of $BYPASS and $ENV{HARNESS_ACTIVE}
#   - import() rejecting undef and reference values as invalid identifiers
#   - can() on a protected method: wrapper returned; access still enforced
#   - Protected sub returning false values (undef, 0, empty string)
#   - Protected sub that dies: error propagates unmodified through the wrapper
#   - goto &$code: positional args forwarded correctly
#   - Cross-package: protected sub in Pkg A calling protected sub in Pkg B is blocked
#   - Double-wrapping: _process_one called twice on the same sub still works
#   - import() return value in list context
#   - config{harness_bypass} change takes immediate effect
#   - $_ not clobbered by the croak path of _check_access
#
# NOTE ON UNREACHABLE PATH:
#   The branch in _check_access that croaks with
#   "... cannot be called outside any package context" is believed
#   unreachable in any normal test environment.  See the detailed
#   annotation near the end of this file for the rationale.

use strict;
use warnings;

# Untaint HOME so that prove -lt does not reject the lib paths
BEGIN {
	my ($home) = ($ENV{HOME} =~ /\A(.+)\z/ms);
	unshift @INC, 'lib',
		"$home/src/njh/Test-Mockingbird/lib",
		"$home/src/njh/Test-Returns/lib";
}

use Test::Most;
use Test::Returns;
use Readonly;
use Scalar::Util qw(reftype blessed);

# Loading Sub::Protected fires CHECK and sets $_post_check = 1.
use Sub::Protected;

# -------------------------------------------------------------------
# Constants -- no magic strings or magic numbers anywhere in the file
# -------------------------------------------------------------------

Readonly::Scalar my $SP      => 'Sub::Protected';

# Configuration hash (Object::Configure-compatible layout)
my %config = (
	owner_pkg      => 'ET::Owner',
	stranger_pkg   => 'ET::Stranger',
	cross_a_pkg    => 'ET::CrossA',
	secret_result  => 'et_secret',
	sum_result     => 7,          # 3 + 4
	join_result    => 'foo:bar:baz',
	dw_result      => 'dw_value',
	die_msg        => 'et_die_msg',
	n_truthy_vals  => 3,
	n_falsy_vals   => 3,
	bypass_sentinel => 'ext_croak_sentinel',
);

# -------------------------------------------------------------------
# Package fixtures -- ALL defined at compile time so :Protected subs
# are wrapped during the CHECK phase as documented.
# -------------------------------------------------------------------

# ET::Owner: the owner package; covers attribute form, false returns, die, args
{
	package ET::Owner;
	use Sub::Protected;

	sub new         { bless {}, shift }
	sub _secret     :Protected { 'et_secret' }
	sub _ret_undef  :Protected { return undef }
	sub _ret_zero   :Protected { return 0 }
	sub _ret_empty  :Protected { return q{} }
	sub _die_inner  :Protected { die "et_die_msg\n" }
	# _add_args: two numeric positional args (after self)
	sub _add_args   :Protected { my (undef, $a, $b) = @_; $a + $b }
	# _join_args: variadic string args joined with ':'
	sub _join_args  :Protected { my (undef, @rest) = @_; join ':', @rest }

	# Public trampolines that call each protected sub from owner context
	sub call_secret  { (shift)->_secret }
	sub call_undef   { (shift)->_ret_undef }
	sub call_zero    { (shift)->_ret_zero }
	sub call_empty   { (shift)->_ret_empty }
	sub call_die     { (shift)->_die_inner }
	sub call_add     { my $s = shift; $s->_add_args(@_) }
	sub call_join    { my $s = shift; $s->_join_args(@_) }
}

# ET::Stranger -- no ISA relation to ET::Owner; all protected calls must croak
{
	package ET::Stranger;
	sub new   { bless {}, shift }
	sub probe { ET::Owner->new->_secret }
}

# ET::CrossA and ET::CrossB for the cross-package protected-to-protected test
{
	package ET::CrossA;
	use Sub::Protected;
	sub new   { bless {}, shift }
	sub _data :Protected { 'cross_a_data' }
	sub get   { (shift)->_data }
}

{
	package ET::CrossB;
	use Sub::Protected;
	sub new { bless {}, shift }

	# _invade is protected in CrossB but calls CrossA's protected sub.
	# The check for CrossA::_data sees ET::CrossB as the first non-SP caller
	# and must block it since CrossB is not CrossA or a subclass of CrossA.
	sub _invade :Protected { ET::CrossA->new->_data }
	sub attempt { (shift)->_invade }
}

# ET::DoubleWrap and its stranger: used for the double-wrapping test
{
	package ET::DoubleWrap;
	use Sub::Protected qw(_dw_sub);

	sub new     { bless {}, shift }
	sub _dw_sub { $config{dw_result} }
	sub run     { (shift)->_dw_sub }
}

{
	package ET::DWStranger;
	sub new   { bless {}, shift }
	sub probe { ET::DoubleWrap->new->_dw_sub }
}

# SP::Sub: a subclass of Sub::Protected for the _assert_private_caller isa test.
# The isa branch: caller(1) is SP::Sub; SP::Sub->isa('Sub::Protected') is true.
{
	package SP::Sub;
	our @ISA = ('Sub::Protected');

	# Both helpers are compiled in SP::Sub so caller() inside
	# _assert_private_caller sees SP::Sub as the guarded method's caller.
	sub _ext_inner { Sub::Protected::_assert_private_caller('_ext_inner') }
	sub _ext_outer { SP::Sub::_ext_inner() }
}

diag "Starting extended coverage tests for $SP" if $ENV{TEST_VERBOSE};

# ===================================================================
# SECTION 1: harness_bypass=0 -- all guarded functions still enforce
#
# POD: "The HARNESS_ACTIVE bypass can be disabled by setting:
#       $Sub::Protected::config{harness_bypass} = 0"
# ===================================================================

subtest 'harness_bypass=0: _check_access enforces even with HARNESS_ACTIVE=1' => sub {
	plan tests => 2;

	# Disable harness_bypass so HARNESS_ACTIVE is ignored; BYPASS is also off.
	local $Sub::Protected::config{harness_bypass} = 0;
	local $ENV{HARNESS_ACTIVE}                    = 1;
	local $Sub::Protected::BYPASS                 = 0;

	# Stranger must be blocked even though HARNESS_ACTIVE is truthy
	throws_ok { ET::Stranger->new->probe }
		qr/protected method/,
		'harness_bypass=0: stranger blocked even with HARNESS_ACTIVE=1';

	# Owner must still be allowed (protection is enforced, not disabled)
	lives_ok { ET::Owner->new->call_secret }
		'harness_bypass=0: owner access still works';
};

subtest 'harness_bypass=0: _wrap private guard fires with HARNESS_ACTIVE=1' => sub {
	plan tests => 1;

	local $Sub::Protected::config{harness_bypass} = 0;
	local $ENV{HARNESS_ACTIVE}                    = 1;
	local $Sub::Protected::BYPASS                 = 0;

	# The private-caller guard on _wrap must croak even with HARNESS_ACTIVE
	throws_ok {
		Sub::Protected::_wrap('Some::Pkg', '_some_sub', sub { 1 });
	} qr/_wrap\(\) is a private method of \Q$SP\E/,
		'_wrap guard fires when harness_bypass=0 and HARNESS_ACTIVE=1';
};

subtest 'harness_bypass=0: _process_one private guard fires with HARNESS_ACTIVE=1' => sub {
	plan tests => 1;

	local $Sub::Protected::config{harness_bypass} = 0;
	local $ENV{HARNESS_ACTIVE}                    = 1;
	local $Sub::Protected::BYPASS                 = 0;

	# The private-caller guard on _process_one must croak even with HARNESS_ACTIVE
	throws_ok {
		Sub::Protected::_process_one('ET::Owner', '_secret');
	} qr/_process_one\(\) is a private method of \Q$SP\E/,
		'_process_one guard fires when harness_bypass=0 and HARNESS_ACTIVE=1';
};

subtest 'harness_bypass=0: config change takes immediate runtime effect' => sub {
	plan tests => 2;

	# First confirm the baseline: HARNESS_ACTIVE=1 allows by default
	{
		local $ENV{HARNESS_ACTIVE}    = 1;
		local $Sub::Protected::BYPASS = 0;

		lives_ok { ET::Stranger->new->probe }
			'baseline: HARNESS_ACTIVE=1 allows stranger when harness_bypass=1';
	}

	# Now flip harness_bypass off -- stranger must be blocked immediately
	{
		local $Sub::Protected::config{harness_bypass} = 0;
		local $ENV{HARNESS_ACTIVE}                    = 1;
		local $Sub::Protected::BYPASS                 = 0;

		throws_ok { ET::Stranger->new->probe }
			qr/protected method/,
			'stranger blocked immediately after harness_bypass set to 0';
	}
};

# ===================================================================
# SECTION 2: _assert_private_caller -- Sub::Protected subclass allowed
#
# The guard code: return if $caller eq $SELF || eval { $caller->isa($SELF) }
# Tests the ->isa() branch using SP::Sub, which extends Sub::Protected.
# ===================================================================

subtest '_assert_private_caller: allows caller that is a Sub::Protected subclass' => sub {
	plan tests => 1;

	# SP::Sub::_ext_outer -> _ext_inner -> _assert_private_caller.
	# caller(1) inside _assert_private_caller = SP::Sub.
	# SP::Sub->isa('Sub::Protected') is true, so the guard returns normally.
	lives_ok { SP::Sub::_ext_outer() }
		'_assert_private_caller: Sub::Protected subclass passes the isa() check';
};

# ===================================================================
# SECTION 3: $BYPASS truthy and falsy value sweep
#
# POD: "$Sub::Protected::BYPASS set to a true value"
# Any Perl-true value must bypass; any Perl-false value must not.
# ===================================================================

subtest '$BYPASS: truthy non-1 values all bypass access checks' => sub {
	plan tests => $config{n_truthy_vals};

	local $ENV{HARNESS_ACTIVE} = 0;

	# Test three distinct truthy string/integer values
	for my $v ('yes', '1', 2) {
		local $Sub::Protected::BYPASS = $v;
		lives_ok { ET::Stranger->new->probe }
			"\$BYPASS='$v' (truthy) allows stranger";
	}
};

subtest '$BYPASS: falsy values do not bypass access checks' => sub {
	plan tests => $config{n_falsy_vals};

	local $ENV{HARNESS_ACTIVE} = 0;

	# Test three falsy values: integer 0, empty string, string '0'
	for my $v (0, q{}, '0') {
		local $Sub::Protected::BYPASS = $v;
		my $label = length("$v") ? qq{"$v"} : q{""};
		throws_ok { ET::Stranger->new->probe }
			qr/protected method/,
			"\$BYPASS=$label (falsy) still enforces access";
	}
};

# ===================================================================
# SECTION 4: HARNESS_ACTIVE truthy and falsy sweep
#
# POD: "$ENV{HARNESS_ACTIVE} set (the convention used by Test::Harness)"
# Truthy env strings bypass; '0' and '' do not.
# ===================================================================

subtest 'HARNESS_ACTIVE: truthy string values bypass access checks' => sub {
	plan tests => $config{n_truthy_vals};

	local $Sub::Protected::BYPASS = 0;
	# harness_bypass must be 1 (its default) for HARNESS_ACTIVE to take effect

	for my $v ('1', 'yes', 'true') {
		local $ENV{HARNESS_ACTIVE} = $v;
		lives_ok { ET::Stranger->new->probe }
			"HARNESS_ACTIVE='$v' (truthy) allows stranger";
	}
};

subtest 'HARNESS_ACTIVE: falsy values do not bypass access checks' => sub {
	plan tests => $config{n_falsy_vals};

	local $Sub::Protected::BYPASS = 0;

	# Test three falsy values: string '0', empty string, integer 0
	for my $v ('0', q{}, 0) {
		local $ENV{HARNESS_ACTIVE} = $v;
		my $label = length("$v") ? qq{"$v"} : q{""};
		throws_ok { ET::Stranger->new->probe }
			qr/protected method/,
			"HARNESS_ACTIVE=$label (falsy) still enforces access";
	}
};

# ===================================================================
# SECTION 5: import() with invalid input types
#
# import() must reject undef and reference values with the documented
# "is not a valid Perl identifier" croak, not a downstream error.
# ===================================================================

subtest 'import(): undef sub name rejected as invalid identifier' => sub {
	plan tests => 1;

	# Previously, undef slipped past validate_strict and reached _process_one,
	# producing "main:: is not defined" instead of the documented error.
	# The fix: coerce undef to '' before validate_strict so the regex fires.
	throws_ok { Sub::Protected->import(undef) }
		qr/is not a valid Perl identifier/,
		'import(undef) croaks with "not a valid Perl identifier"';
};

subtest 'import(): hashref sub name rejected as invalid identifier' => sub {
	plan tests => 1;

	# A hashref is not a valid identifier string; must be caught at validation.
	throws_ok { Sub::Protected->import({}) }
		qr/is not a valid Perl identifier/,
		'import({}) croaks with "not a valid Perl identifier"';
};

# ===================================================================
# SECTION 6: can() on a protected sub -- wrapper returned, access enforced
#
# The :Protected attribute wraps the sub at CHECK time.  can() therefore
# returns the wrapper closure.  Calling the wrapper from an unrelated
# package must still trigger _check_access and croak.
# ===================================================================

subtest 'can(): returns the wrapper CODE ref, not undef' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# can() must find the wrapped version of _secret
	my $code = ET::Owner->can('_secret');
	ok defined($code),           'can() returns a defined value for a protected sub';
	is reftype($code), 'CODE',   'can() return is a CODE reference (the wrapper)';
};

subtest 'can(): calling wrapper from unrelated package still blocked' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	my $code = ET::Owner->can('_secret');

	# Calling the closure obtained from can() from an unrelated package
	# must still invoke _check_access and croak with "protected method"
	throws_ok {
		package ET::CanStranger;
		$code->(ET::Owner->new);
	} qr/protected method/,
		'wrapper from can() blocks unrelated caller';
};

subtest 'can(): calling wrapper from owner context is allowed' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	my $code = ET::Owner->can('_secret');

	# Compiling the call inside "package ET::Owner" sets the package context,
	# so _check_access sees ET::Owner as the first non-SP frame.
	lives_ok {
		package ET::Owner;
		$code->(ET::Owner->new);
	} 'wrapper from can() is callable from owner context';
};

# ===================================================================
# SECTION 7: Protected sub returning false values
#
# goto &$code must not suppress undef, 0, or empty-string returns.
# ===================================================================

subtest 'protected sub returning undef: undef propagates through wrapper' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# The wrapper must not coerce the undef return into something defined
	my $result = ET::Owner->new->call_undef;
	ok !defined($result), 'undef return value propagates through wrapper';

	# Also confirm the call does not croak
	lives_ok { ET::Owner->new->call_undef }
		'protected sub returning undef does not croak';
};

subtest 'protected sub returning 0: zero propagates through wrapper' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	my $result = ET::Owner->new->call_zero;
	is $result, 0, 'zero return value propagates through wrapper';
	ok !$result,   'returned zero is still falsy';
};

subtest 'protected sub returning empty string: propagates through wrapper' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	my $result = ET::Owner->new->call_empty;
	is $result, q{},  'empty-string return value propagates through wrapper';
	ok !$result,      'returned empty string is still falsy';
};

# ===================================================================
# SECTION 8: Protected sub that dies -- error propagates unmodified
#
# When the protected sub calls die, the exception must propagate
# through the wrapper without being swallowed or modified.
# ===================================================================

subtest 'protected sub that dies: error propagates from owner context' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# The die message must reach the caller
	throws_ok { ET::Owner->new->call_die }
		qr/\Q$config{die_msg}\E/,
		'die inside protected sub propagates to outer caller';

	# The propagated error must NOT look like a protection croak
	eval { ET::Owner->new->call_die };
	unlike $@, qr/protected method/,
		'propagated error does not contain "protected method"';
};

# ===================================================================
# SECTION 9: goto &$code -- positional args forwarded correctly
#
# The wrapper uses 'goto &$code', which replaces the wrapper's own
# frame and passes @_ unchanged.  Verify numeric and string args arrive.
# ===================================================================

subtest 'goto &$code: numeric positional args forwarded' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# _add_args(self, 3, 4) should return 3+4 = 7
	my $sum = ET::Owner->new->call_add(3, 4);
	is $sum, $config{sum_result}, 'goto &$code forwards numeric args correctly';
};

subtest 'goto &$code: variadic string args forwarded and joined' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# _join_args(self, 'foo', 'bar', 'baz') should join with ':' -> 'foo:bar:baz'
	my $joined = ET::Owner->new->call_join('foo', 'bar', 'baz');
	is $joined, $config{join_result}, 'goto &$code forwards variadic string args';
};

# ===================================================================
# SECTION 10: Cross-package: protected-to-protected call is blocked
#
# ET::CrossB::_invade (protected in CrossB) calls ET::CrossA::_data
# (protected in CrossA) from within the _invade body.  After goto
# unwinds the _invade wrapper, the real frame is ET::CrossB -- which is
# not ET::CrossA, so _check_access for _data must croak.
# ===================================================================

subtest 'cross-package: ET::CrossA owner can call its own protected sub' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	lives_ok { ET::CrossA->new->get }
		'ET::CrossA owner can call its own protected sub';
};

subtest 'cross-package: ET::CrossB blocked from ET::CrossA protected sub' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# ET::CrossB::attempt -> _invade (protected) -> ET::CrossA::_data (protected).
	# The access check for _data sees ET::CrossB as the first external caller.
	throws_ok { ET::CrossB->new->attempt }
		qr/_data\(\) is a protected method of \Q$config{cross_a_pkg}\E/,
		'ET::CrossB is blocked from ET::CrossA::_data';
};

# ===================================================================
# SECTION 11: Double-wrapping via repeated _process_one calls
#
# If _process_one is called twice on the same sub (which is already a
# wrapper), the outer wrapper wraps the inner wrapper.  Both checks fire
# but the result is correct: owner allowed, stranger blocked.
# ===================================================================

subtest 'double-wrapping: owner still works after second _process_one call' => sub {
	plan tests => 2;

	# Wrap ET::DoubleWrap::_dw_sub a second time (first wrap is from the fixture's
	# declarative import above).  BYPASS=1 to bypass the private-caller guard.
	{
		local $Sub::Protected::BYPASS = 1;
		Sub::Protected::_process_one('ET::DoubleWrap', '_dw_sub');
	}

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# Owner calling through public trampoline must still succeed
	my $result;
	lives_ok { $result = ET::DoubleWrap->new->run }
		'double-wrapped: owner can still call the sub';
	is $result, $config{dw_result}, 'double-wrapped: correct return value';
};

subtest 'double-wrapping: stranger still blocked after second wrap' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	throws_ok { ET::DWStranger->new->probe }
		qr/protected method/,
		'double-wrapped sub still blocks unrelated caller';
};

# ===================================================================
# SECTION 12: import() return value in list context
# ===================================================================

subtest 'import(): list context returns one-element list containing class name' => sub {
	plan tests => 2;

	# Calling import() in list context must still return exactly one value
	my @result = Sub::Protected->import();
	is scalar(@result), 1,   'import() returns a single-element list in list context';
	is $result[0], $SP,      'the element is the class name';
};

# ===================================================================
# SECTION 13: $_ not clobbered by the croak path of _check_access
# ===================================================================

subtest '$_ not clobbered when _check_access croaks' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	local $_ = $config{bypass_sentinel};
	eval { ET::Stranger->new->probe };    # expected croak; check $_ survives
	is $_, $config{bypass_sentinel}, '$_ unchanged after _check_access croak';
};

# ===================================================================
# UNREACHABLE PATH ANNOTATION
#
# The following branch in _check_access:
#
#   if (!defined $pkg) {
#       croak "${sub_name}() is a protected method of ${owner_pkg}"
#           . ' and cannot be called outside any package context';
#   }
#
# is believed unreachable in any normal test environment.
#
# Rationale: the stack walk starts at frame 0 (the wrapper closure,
# compiled in Sub::Protected) and increments past Sub::Protected frames
# until it finds the first non-SP package.  In every real Perl execution
# environment there is always at least one non-SP frame on the stack
# below the wrapper -- the test script itself appears as 'main' (or the
# test runner's package), and Perl always maintains this as a live frame.
#
# To reach the "!defined $pkg" branch one would need to construct a call
# stack where EVERY frame is in package Sub::Protected, with no Perl
# caller below them.  That would require executing code from XS or from
# an eval-only context with no normal Perl frames below -- situations
# that cannot be induced from a Perl test script.
#
# A verification probe was tried: calling _check_access from a helper
# compiled entirely within "package Sub::Protected" still finds 'main'
# at the bottom of the stack and croaks with "cannot be called from main"
# (the normal path), NOT with "outside any package context".
#
# The path is retained in the production code as a defensive guard.
# It cannot be covered by any Perl-level test.
#
# Commented-out test sketch (retained for human review):
#
#   subtest '_check_access: "outside any package context" (UNREACHABLE)' => sub {
#       plan tests => 1;
#
#       # CANNOT BE REACHED: caller() always returns a non-SP frame
#       # (at minimum the test file itself as 'main').
#       # If ever triggered (e.g. from XS), the expected message is:
#       # qr/cannot be called outside any package context/
#       #
#       # throws_ok { <hypothetical all-SP call chain> }
#       #     qr/cannot be called outside any package context/,
#       #     'top-of-stack path';
#   };
# ===================================================================

done_testing;
