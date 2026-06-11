#!/usr/bin/perl
# t/edge_cases.t -- Destructive, pathological, boundary-condition and security tests.
#
# Sections:
#  1. Original edge cases (false-y returns, arg forwarding, die propagation, can(), attr/decl, twins)
#  2. Pathological import() inputs (undef, refs, empty, bad identifiers)
#  3. Mode validation boundary conditions
#  4. $_ preservation through wrapper and access-check paths
#  5. Context (wantarray) propagation through goto &$code
#  6. Subclass access blocked (no ->isa allowance)
#  7. Private-calls-private re-entrancy (same package)
#  8. Non-existent sub in declarative form
#  9. Namespace mode rejects declarative form
# 10. Large argument lists through wrapper
# 11. Circular references returned through wrapper
# 12. Rebless bypass attempt (security)
# 13. Exact error message format verification
# 14. Raw coderef obtained after wrapping is still blocked
# 15. BYPASS flag is dynamically scoped
# 16. Fail-fast all-or-nothing validation in import()
# 17. Deeply nested package names in error messages
# 18. _assert_known_mode positive boundary (valid modes accepted)
# 19. Single underscore "_" is a valid sub name boundary
# 20. Spy/mock verification (conditional on Test::Mockingbird)

use strict;
use warnings;

use Test::Most;
use Scalar::Util qw(weaken);
use Readonly;

# Enforce mode so attribute handlers install wrappers rather than removing subs.
# Must be set before 'use Sub::Private' so CHECK fires with the right mode.
BEGIN { $Sub::Private::config{mode} = 'enforce' }

use Sub::Private;

# Disable both bypass paths so enforcement fires on every test unless overridden.
local $ENV{HARNESS_ACTIVE}  = 0;
local $Sub::Private::BYPASS = 0;

# ---------------------------------------------------------------------------
# Configuration constants -- no magic strings in the test body
# ---------------------------------------------------------------------------

Readonly::Scalar my $SP           => 'Sub::Private';
Readonly::Scalar my $MSG_PRIVATE  => qr/private subroutine/;
Readonly::Scalar my $MSG_NOT_DEFN => qr/is not defined/;
Readonly::Scalar my $MSG_BAD_ID   => qr/is not a valid Perl identifier/;
Readonly::Scalar my $MSG_DECL_NS  => qr/declarative form requires mode => 'enforce'/;
Readonly::Scalar my $MSG_BAD_MODE => qr/unknown mode/;

# Optional: Test::Mockingbird for spy/mock subtests
my $have_mockingbird = eval { require Test::Mockingbird; 1 };

diag 'Test::Mockingbird ' . ($have_mockingbird ? 'available' : 'not available')
	if $ENV{TEST_VERBOSE};

# ===========================================================================
# Section 1: Original edge cases (retained from prior version)
# ===========================================================================

# Fixture: subs returning falsy values (undef, 0, empty string)
{
	package EdgeFalse;
	use Sub::Private;
	sub new       { bless {}, shift }
	sub _undef    :Private { return undef }
	sub _zero     :Private { return 0 }
	sub _empty    :Private { return q{} }
	sub get_undef  { (shift)->_undef }
	sub get_zero   { (shift)->_zero }
	sub get_empty  { (shift)->_empty }
}

# The wrapper must treat undef/0/"" as legitimate return values, not errors.
subtest 'false-y return values propagate through wrapper' => sub {
	plan tests => 3;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	ok !defined( EdgeFalse->new->get_undef ), 'undef propagates through wrapper';
	is( EdgeFalse->new->get_zero,  0,   '0 propagates through wrapper' );
	# Empty string must propagate, not be coerced to undef or 0
	is( EdgeFalse->new->get_empty, q{}, '"" propagates through wrapper' );
};

# Fixture: checks that positional arguments survive goto &$code unchanged
{
	package EdgeArgs;
	use Sub::Private;
	sub new { bless {}, shift }
	sub _sum :Private { my (undef, $a, $b) = @_; $a + $b }
	sub run  { my $s = shift; $s->_sum(@_) }
}

subtest 'goto &$code forwards positional args correctly' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	# 10 + 20 = 30; any arg corruption through the wrapper would produce a wrong result.
	is( EdgeArgs->new->run(10, 20), 30, '10 + 20 = 30 forwarded correctly' );
};

# Fixture: private sub that throws an exception
{
	package EdgeDie;
	use Sub::Private;
	sub new    { bless {}, shift }
	sub _boom  :Private { die "kaboom\n" }
	sub invoke { (shift)->_boom }
}

# The wrapper must not swallow or modify the exception thrown inside.
subtest 'die inside private sub propagates unmodified' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	throws_ok { EdgeDie->new->invoke } qr/kaboom/, 'die message propagates through wrapper';
};

# In enforce mode, can() returns the wrapper coderef, but the wrapper still enforces.
subtest 'can() in enforce mode: wrapper returned but still enforces access' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	my $code = EdgeFalse->can('_undef');
	# Private sub is still in the stash (as a wrapper), so can() is truthy.
	ok defined($code), 'can() returns defined coderef for :Private sub in enforce mode';

	# The wrapper obtained via can() must still block an unrelated caller.
	throws_ok {
		package EdgeCanProber;
		$code->(EdgeFalse->new);
	} $MSG_PRIVATE, 'wrapper from can() blocks unrelated caller';
};

# Attribute (:Private) form and declarative (qw) form must behave identically.
{
	package EdgeAttrPkg;
	use Sub::Private;
	sub new  { bless {}, shift }
	sub _sec :Private { 'attr-sec' }
	sub pub  { (shift)->_sec }
}

{
	package EdgeDeclPkg;
	use Sub::Private qw(_sec);
	sub new  { bless {}, shift }
	sub _sec { 'decl-sec' }
	sub pub  { (shift)->_sec }
}

{
	package EdgeOutsider;
	sub probe_attr { EdgeAttrPkg->new->_sec }
	sub probe_decl { EdgeDeclPkg->new->_sec }
}

subtest 'attr form and declarative form enforce identically' => sub {
	plan tests => 4;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	lives_ok { EdgeAttrPkg->new->pub } 'attr form: owner access allowed';
	lives_ok { EdgeDeclPkg->new->pub } 'decl form: owner access allowed';
	# Both forms must block an outsider with the same error pattern
	throws_ok { EdgeOutsider::probe_attr() } $MSG_PRIVATE, 'attr form: outsider blocked';
	throws_ok { EdgeOutsider::probe_decl() } $MSG_PRIVATE, 'decl form: outsider blocked';
};

# Fixture: two independently wrapped subs in the same package
{
	package EdgeTwin;
	use Sub::Private;
	sub new   { bless {}, shift }
	sub _p    :Private { 'p' }
	sub _q    :Private { 'q' }
	sub get_p { (shift)->_p }
	sub get_q { (shift)->_q }
}

# Each wrapped sub must have its own independent enforcement closure.
subtest 'two independently wrapped subs enforce independently' => sub {
	plan tests => 4;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	lives_ok { EdgeTwin->new->get_p } 'owner can call _p';
	lives_ok { EdgeTwin->new->get_q } 'owner can call _q';
	# Blocking _p must not affect _q (independent closures)
	throws_ok { EdgeTwin::_p(EdgeTwin->new) } $MSG_PRIVATE, '_p blocked from outside';
	throws_ok { EdgeTwin::_q(EdgeTwin->new) } $MSG_PRIVATE, '_q blocked from outside';
};

# ===========================================================================
# Section 2: Pathological import() inputs
# ===========================================================================

# Each of the following should croak "is not a valid Perl identifier".
# The module coerces undef/refs to '' before the identifier regex check.

subtest 'import() rejects undef as sub name' => sub {
	plan tests => 1;
	throws_ok { Sub::Private->import(undef) } $MSG_BAD_ID, 'undef in sub name list rejected';
};

subtest 'import() rejects arrayref as sub name' => sub {
	plan tests => 1;
	throws_ok { Sub::Private->import([]) } $MSG_BAD_ID, 'arrayref as sub name rejected';
};

# A coderef is a reference type; it is coerced to '' before checking.
subtest 'import() rejects coderef as sub name' => sub {
	plan tests => 1;
	throws_ok { Sub::Private->import(sub { }) } $MSG_BAD_ID, 'coderef as sub name rejected';
};

subtest 'import() rejects hashref as sub name' => sub {
	plan tests => 1;
	throws_ok { Sub::Private->import({}) } $MSG_BAD_ID, 'hashref as sub name rejected';
};

# Empty string fails the regex \A[_a-zA-Z]\w*\z because there is no first char.
subtest 'import() rejects empty string as sub name' => sub {
	plan tests => 1;
	throws_ok { Sub::Private->import(q{}) } $MSG_BAD_ID, 'empty string as sub name rejected';
};

# Names that start with a digit are not legal Perl sub names.
subtest 'import() rejects name starting with a digit' => sub {
	plan tests => 1;
	throws_ok { Sub::Private->import('123bad') } $MSG_BAD_ID, 'digit-leading name rejected';
};

subtest 'import() rejects name starting with digit zero "0"' => sub {
	plan tests => 1;
	throws_ok { Sub::Private->import('0') } $MSG_BAD_ID, 'bare "0" as sub name rejected';
};

# Hyphens and spaces are not legal in Perl identifiers.
subtest 'import() rejects name containing a hyphen' => sub {
	plan tests => 1;
	throws_ok { Sub::Private->import('bad-name') } $MSG_BAD_ID, 'hyphen in name rejected';
};

subtest 'import() rejects name containing a space' => sub {
	plan tests => 1;
	throws_ok { Sub::Private->import('bad name') } $MSG_BAD_ID, 'space in name rejected';
};

# Dot is not a word character; it is not allowed in sub names.
subtest 'import() rejects name containing a dot' => sub {
	plan tests => 1;
	throws_ok { Sub::Private->import('bad.name') } $MSG_BAD_ID, 'dot in name rejected';
};

# ===========================================================================
# Section 3: Mode validation boundary conditions
# ===========================================================================

# _assert_known_mode has no _assert_private_caller guard; callable directly.

# Positive: both documented mode strings must be accepted without error.
subtest '_assert_known_mode accepts "namespace" and "enforce"' => sub {
	plan tests => 2;
	lives_ok { Sub::Private::_assert_known_mode('namespace') } '"namespace" is a valid mode';
	lives_ok { Sub::Private::_assert_known_mode('enforce')   } '"enforce" is a valid mode';
};

subtest 'unknown mode value croaks with canonical message' => sub {
	plan tests => 1;
	throws_ok {
		Sub::Private::_assert_known_mode('bogus');
	} $MSG_BAD_MODE, 'unrecognised mode "bogus" produces unknown-mode error';
};

# Mode names are case-sensitive: 'ENFORCE' is not 'enforce'.
subtest "uppercase 'ENFORCE' is not a known mode" => sub {
	plan tests => 1;
	throws_ok {
		Sub::Private::_assert_known_mode('ENFORCE');
	} $MSG_BAD_MODE, '"ENFORCE" (uppercase) is not a valid mode';
};

subtest "uppercase 'NAMESPACE' is not a known mode" => sub {
	plan tests => 1;
	throws_ok {
		Sub::Private::_assert_known_mode('NAMESPACE');
	} $MSG_BAD_MODE, '"NAMESPACE" (uppercase) is not a valid mode';
};

# Empty string must also be rejected (not a valid mode).
subtest "empty string is not a known mode" => sub {
	plan tests => 1;
	throws_ok {
		Sub::Private::_assert_known_mode(q{});
	} $MSG_BAD_MODE, 'empty string is not a valid mode';
};

# ===========================================================================
# Section 4: $_ preservation through wrapper and access-check paths
# ===========================================================================

# Fixture: private sub that does NOT modify $_ -- used to test the wrapper's
# own behaviour, not the private sub's behaviour.
{
	package EdgeUnderscorePkg;
	use Sub::Private;
	sub new      { bless {}, shift }
	sub _private :Private { 'result' }
	sub go       { (shift)->_private }
}

subtest '$_ is preserved on the happy path (wrapper must not clobber $_)' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	# If the wrapper or _check_access accidentally clobbers $_, this fails.
	local $_ = 'sentinel';
	EdgeUnderscorePkg->new->go;
	is $_, 'sentinel', '$_ intact after successful private method call';
};

# The croak path inside _check_access must also leave $_ untouched.
subtest '$_ is preserved when _check_access croaks (outsider blocked)' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	local $_ = 'guard';
	# Direct outsider call: the wrapper croaks inside _check_access.
	eval { EdgeUnderscorePkg->new->_private };
	is $_, 'guard', '$_ intact after _check_access croak (outsider blocked path)';
};

# ===========================================================================
# Section 5: Context (wantarray) propagation through goto &$code
# ===========================================================================

# Fixture: private sub that returns different values in list vs scalar context.
{
	package EdgeContext;
	use Sub::Private;
	sub new { bless {}, shift }
	sub _ctx :Private {
		return wantarray ? ('list', 'context') : 'scalar context';
	}
	# get_list forces list context; get_scalar forces scalar context
	sub get_list   { my $s = shift; return $s->_ctx }
	sub get_scalar { my $s = shift; my $r = $s->_ctx; return $r }
}

subtest 'list context is propagated correctly through goto &$code' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	my @result = EdgeContext->new->get_list;
	is_deeply \@result, ['list', 'context'], 'list context forwarded through wrapper';
};

# goto must preserve scalar context so the private sub sees the right wantarray().
subtest 'scalar context is propagated correctly through goto &$code' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	my $result = EdgeContext->new->get_scalar;
	is $result, 'scalar context', 'scalar context forwarded through wrapper';
};

# ===========================================================================
# Section 6: Subclass access blocked (no ->isa allowance)
# ===========================================================================

# Fixture: base class with a private sub, and a subclass that tries to steal it.
{
	package EdgeBase;
	use Sub::Private;
	sub new    { bless {}, shift }
	sub _priv  :Private { 'base secret' }
	sub reveal { (shift)->_priv }
}

{
	package EdgeChild;
	our @ISA = ('EdgeBase');
	# steal() is defined in EdgeChild, so caller() inside _check_access = EdgeChild.
	sub steal { my $s = shift; $s->_priv }
}

subtest 'subclass access to parent private sub' => sub {
	plan tests => 3;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	# Owner calling through its own method: caller = EdgeBase = owner -- allowed.
	lives_ok { EdgeBase->new->reveal }
		'EdgeBase can call _priv via its own reveal()';

	# Subclass inheriting reveal(): reveal() code lives in EdgeBase, so caller
	# is EdgeBase -- allowed even when $self is an EdgeChild instance.
	lives_ok { EdgeChild->new->reveal }
		'EdgeChild instance using inherited EdgeBase::reveal() is allowed';

	# EdgeChild defining its own method that calls _priv: caller = EdgeChild -- blocked.
	throws_ok { EdgeChild->new->steal } $MSG_PRIVATE,
		'subclass blocked from calling parent private sub via its own method';
};

# ===========================================================================
# Section 7: Private-calls-private re-entrancy (same package)
# ===========================================================================

# Fixture: one private sub calls another private sub in the same package.
{
	package EdgeReentrant;
	use Sub::Private;
	sub new    { bless {}, shift }
	sub _inner :Private { 'inner' }
	# _outer calls _inner: both private to the same owner, so caller checks pass.
	sub _outer :Private { my $s = shift; 'outer+' . $s->_inner }
	sub go     { (shift)->_outer }
}

subtest 'private sub may call another private sub in the same package' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	# goto makes the wrapper frame invisible; _outer's code sees caller = EdgeReentrant.
	is( EdgeReentrant->new->go, 'outer+inner', 'private-calls-private re-entrancy works' );
};

# ===========================================================================
# Section 8: Non-existent sub in declarative form
# ===========================================================================

# Fixture: package with no sub definitions (the named sub does not exist).
{
	package EdgeNoSuch;
	# Intentionally empty: _no_such_sub is never defined.
}

subtest 'declarative form croaks when named sub is not defined' => sub {
	plan tests => 1;
	# import() calls _process_one internally via Sub::Private, so the
	# _assert_private_caller guard sees caller(1) = Sub::Private and passes.
	throws_ok {
		package EdgeNoSuch;
		Sub::Private->import('_no_such_sub');
	} $MSG_NOT_DEFN, 'undefined sub causes croak in declarative form';
};

# ===========================================================================
# Section 9: Namespace mode rejects declarative form
# ===========================================================================

{
	package EdgeNsDeclPkg;
	sub _ns_helper { 1 }
}

subtest 'declarative form croaks in namespace mode with exact message' => sub {
	plan tests => 1;
	# Temporarily switch to namespace mode at runtime for this explicit import call.
	# 'local' on a hash element is valid Perl and restores on scope exit.
	local $Sub::Private::config{mode} = 'namespace';

	throws_ok {
		package EdgeNsDeclPkg;
		Sub::Private->import('_ns_helper');
	} $MSG_DECL_NS, 'declarative import blocked in namespace mode with canonical message';
};

# ===========================================================================
# Section 10: Large argument lists through wrapper
# ===========================================================================

{
	package EdgeLargeArgs;
	use Sub::Private;
	sub new      { bless {}, shift }
	# _sum_all takes $self plus an arbitrary list of numbers
	sub _sum_all :Private { my $self = shift; my $t = 0; $t += $_ for @_; $t }
	sub sum      { my $s = shift; $s->_sum_all(@_) }
}

subtest '100-element argument list forwarded correctly through wrapper' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	# Sum of 1..100 = 5050 (Gauss); any arg dropping or reordering fails this.
	Readonly::Scalar my $GAUSS_100 => 5050;
	my @nums = (1 .. 100);
	is( EdgeLargeArgs->new->sum(@nums), $GAUSS_100, '1+2+...+100 = 5050 through wrapper' );
};

# ===========================================================================
# Section 11: Circular references returned through wrapper
# ===========================================================================

{
	package EdgeCircular;
	use Sub::Private;
	sub new         { bless {}, shift }
	# _make_cycle builds a two-node cycle and returns the first node.
	sub _make_cycle :Private {
		my $a = {};
		my $b = { other => $a };
		$a->{other} = $b;
		return $a;
	}
	sub cycle { (shift)->_make_cycle }
}

subtest 'circular reference returned intact through wrapper without corruption' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	# The wrapper must not inspect, copy, or corrupt the circular structure.
	my $node = EdgeCircular->new->cycle;
	is ref($node),          'HASH', 'circular structure root is a HASH ref';
	is ref($node->{other}), 'HASH', 'back-pointer in circular structure is a HASH ref';
};

# ===========================================================================
# Section 12: Rebless bypass attempt (security)
# ===========================================================================

# Fixture: attacker tries to gain access by reblessing itself into the owner class.
{
	package EdgeVault;
	use Sub::Private;
	sub new     { bless {}, shift }
	sub _secret :Private { 'vault secret' }
}

{
	package EdgeAttacker;
	sub new { bless {}, shift }
	# attack() reblesses $self into EdgeVault then calls _secret.
	# _check_access uses caller(), which is package-based (not object-class-based),
	# so the rebless has no effect on the caller() value.
	sub attack {
		my $self = shift;
		bless $self, 'EdgeVault';    # rebless to owner class -- still blocked
		EdgeVault::_secret($self);
	}
}

subtest 'rebless into owner class does not bypass enforcement' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	# caller() reports EdgeAttacker regardless of what the object is blessed into.
	throws_ok { EdgeAttacker->new->attack } $MSG_PRIVATE,
		'rebless into owner class does not grant access to private sub';
};

# ===========================================================================
# Section 13: Exact error message format verification
# ===========================================================================

{
	package EdgeMsgOwner;
	use Sub::Private;
	sub new   { bless {}, shift }
	sub _priv :Private { 'value' }
}

{
	package EdgeMsgCaller;
	sub probe { EdgeMsgOwner->new->_priv }
}

subtest 'error message contains sub name, owner package, and caller package' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	# Documented format: "NAME() is a private subroutine of OWNER and cannot be called from CALLER"
	throws_ok { EdgeMsgCaller::probe() }
		qr/\Q_priv\E\(\) is a private subroutine of \QEdgeMsgOwner\E and cannot be called from \QEdgeMsgCaller\E/,
		'error message format: sub name, owner, and caller all present';
};

# ===========================================================================
# Section 14: Raw coderef obtained after wrapping is still blocked
# ===========================================================================

# Post-CHECK the stash entry for a :Private sub is the wrapper, not the original.
# A raw \& reference to the stash entry gives the wrapper -- which still enforces.
{
	package EdgeGlobVault;
	use Sub::Private;
	sub new     { bless {}, shift }
	sub _secret :Private { 'glob secret' }
}

subtest 'raw coderef obtained after wrapping still blocks outsider' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	# \& gives us the wrapper closure stored in the stash at CHECK time.
	my $code = \&EdgeGlobVault::_secret;

	throws_ok {
		package EdgeGlobProber;
		$code->(EdgeGlobVault->new);
	} $MSG_PRIVATE, 'raw coderef from stash after wrapping still enforces access';
};

# ===========================================================================
# Section 15: BYPASS flag is dynamically scoped
# ===========================================================================

subtest 'BYPASS=1 allows outsider; BYPASS=0 blocks outsider after scope exit' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE} = 0;

	{
		# Inner scope: bypass on -- access check is skipped entirely.
		local $Sub::Private::BYPASS = 1;
		lives_ok { EdgeMsgCaller::probe() } 'BYPASS=1: outsider allowed inside scope';
	}

	# Outer scope: bypass restored to 0 -- outsider must be blocked again.
	local $Sub::Private::BYPASS = 0;
	throws_ok { EdgeMsgCaller::probe() } $MSG_PRIVATE,
		'BYPASS=0: outsider blocked after inner scope exits';
};

# ===========================================================================
# Section 16: Fail-fast all-or-nothing validation in import()
# ===========================================================================

{
	package EdgeFailFast;
	sub _good_ff { 'good' }
}

subtest 'fail-fast: invalid name prevents wrapping of all names (all-or-nothing)' => sub {
	plan tests => 2;

	# The list has one valid name followed by one invalid one.  The entire
	# import must fail: _good_ff must NOT be wrapped because the list failed.
	throws_ok {
		package EdgeFailFast;
		Sub::Private->import('_good_ff', '0bad');
	} $MSG_BAD_ID, 'import() croaks on invalid name in mixed-validity list';

	# If _good_ff had been wrapped, this call from outside would be blocked.
	# It lives, proving fail-fast all-or-nothing was enforced.
	lives_ok { EdgeFailFast::_good_ff() }
		'_good_ff not wrapped due to fail-fast (all-or-nothing)';
};

# ===========================================================================
# Section 17: Deeply nested package names in error messages
# ===========================================================================

{
	package Edge::Deep::Nested::Owner;
	use Sub::Private;
	sub new   { bless {}, shift }
	sub _priv :Private { 'deep' }
}

{
	package Edge::Deep::Nested::Caller;
	sub probe { Edge::Deep::Nested::Owner->new->_priv }
}

subtest 'fully-qualified nested package names appear in error message' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	# Error must contain both full package paths, not just the leaf component.
	throws_ok { Edge::Deep::Nested::Caller::probe() }
		qr/\QEdge::Deep::Nested::Owner\E.*\QEdge::Deep::Nested::Caller\E/s,
		'nested package names preserved verbatim in error message';
};

# ===========================================================================
# Section 18: Underscore-leading name boundary
# ===========================================================================

# "_" alone has special symbol-table treatment in newer Perl (filetest pseudo-handle).
# Use "__" (double underscore): matches \A[_a-zA-Z]\w*\z and has no special meaning.
{
	package EdgeDoubleUnderscore;
	sub __ { 'under' }
}

subtest 'double underscore "__" is accepted as a valid sub name in declarative form' => sub {
	plan tests => 1;

	# In enforce mode with a defined "__" sub, import should succeed.
	lives_ok {
		package EdgeDoubleUnderscore;
		Sub::Private->import('__');
	} 'double underscore is a valid sub name accepted by import()';
};

# ===========================================================================
# Section 19: Spy/mock verification (conditional on Test::Mockingbird)
# ===========================================================================

SKIP: {
	skip 'Test::Mockingbird not available', 3 unless $have_mockingbird;

	Test::Mockingbird->import(qw(spy mock_scoped restore));

	# Spy on Sub::Private::croak (the imported copy) to verify it is called for violations.
	# Mocking Carp::croak would not intercept calls from Sub::Private because the
	# import creates a separate stash entry Sub::Private::croak at compile time.
	subtest 'croak called for enforcement violation (spy verification)' => sub {
		plan tests => 2;
		local $ENV{HARNESS_ACTIVE}  = 0;
		local $Sub::Private::BYPASS = 0;

		# Spy on the imported croak copy in Sub::Private's own stash.
		my $spy_fn = spy('Sub::Private::croak');

		eval { EdgeMsgCaller::probe() };

		my @calls = $spy_fn->();
		diag 'croak spy captured ' . scalar(@calls) . ' call(s)' if $ENV{TEST_VERBOSE};

		# Call record: [ $method_name, $invocant_or_first_arg, @remaining_args ]
		ok @calls >= 1, 'croak was called at least once for the violation';
		# $calls[0][1] is the first argument to croak (the error message string)
		like $calls[0][1], qr/\QEdgeMsgOwner\E/, 'croak message contains owner package name';
	};

	# Fixture package for validate_strict spy; defined at compile time so the subs exist.
	{
		package EdgeVSSpy;
		sub _vs_a { 1 }
		sub _vs_b { 1 }
	}

	# Verify validate_strict is called once per sub name in the declarative list.
	# Target Sub::Private::validate_strict (the imported copy in Sub::Private's stash).
	subtest 'validate_strict called once per sub name in declarative import' => sub {
		plan tests => 1;
		local $Sub::Private::BYPASS = 1;    # bypass _assert_private_caller guard

		my $call_count = 0;

		# Mock the imported copy inside Sub::Private; the guard auto-restores on scope exit.
		my $guard = mock_scoped('Sub::Private::validate_strict', sub {
			$call_count++;
			return { name => 'ok' };    # valid-looking result so import continues
		});

		eval {
			package EdgeVSSpy;
			Sub::Private->import('_vs_a', '_vs_b');
		};

		diag "validate_strict called $call_count time(s)" if $ENV{TEST_VERBOSE};
		is $call_count, 2, 'validate_strict called once per name (2 names -> 2 calls)';
	};

	# Verify that a validate_strict failure produces the documented error message.
	# Target the imported copy so the mock actually intercepts the call.
	subtest 'import() produces documented error when validate_strict dies' => sub {
		plan tests => 1;

		# Guard auto-restores when $guard goes out of scope at subtest end.
		my $guard = mock_scoped('Sub::Private::validate_strict', sub {
			die "UNEXPECTED\n";
		});

		throws_ok {
			Sub::Private->import('_any_name');
		} qr/is not a valid Perl identifier/,
			'documented error produced when validate_strict dies';
	};
}

done_testing;
