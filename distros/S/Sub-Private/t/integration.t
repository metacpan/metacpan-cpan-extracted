#!/usr/bin/perl
# t/integration.t -- end-to-end integration tests for Sub::Private.
#
# Tests full workflows across multiple objects, packages, and interactions
# with third-party OO frameworks.  Internal helpers are not called directly.
# Less mocking than unit tests; Test::Mockingbird::spy is used only where
# verifying that the right external call was made adds confidence.

use strict;
use warnings;

use Test::Most;
use Test::Needs;
use Readonly;

my $have_returns     = eval { require Test::Returns; Test::Returns->import; 1 };
my $have_mockingbird = eval { require Test::Mockingbird; Test::Mockingbird->import; 1 };

# enforce mode so runtime wrapper checks fire for all OO dispatch.
BEGIN { $Sub::Private::config{mode} = 'enforce' }

use_ok 'Sub::Private' or BAIL_OUT 'Sub::Private failed to load';

# -------------------------------------------------------------------
# Constants
# -------------------------------------------------------------------

Readonly::Scalar my $SP      => 'Sub::Private';
Readonly::Scalar my $VERSION => '0.05';

my %config = (
	n_instances    => 5,
	helper_result  => 'helper result',
	step1_result   => 'step1',
	alpha_result   => 'alpha_secret',
	beta_result    => 'beta_secret',
	stateful_init  => 0,
	stateful_delta => 10,
	complex_items  => 3,
);

# -------------------------------------------------------------------
# Fixtures -- all defined at compile time so :Private is processed at CHECK.
# -------------------------------------------------------------------

# ===== Scenario A: basic OO class with a single private sub =====

{
	package IntFoo;
	use Sub::Private;

	sub new         { bless {}, shift }
	sub _helper     :Private { 'helper result' }
	sub call_helper { (shift)->_helper }
}

# Subclass: must be blocked from calling parent's private sub.
{
	package IntFooChild;
	our @ISA = ('IntFoo');
	sub new        { bless {}, shift }
	sub try_helper { (shift)->_helper }
}

{
	package IntVet;
	sub new   { bless {}, shift }
	sub probe { (shift->[0])->_helper }
}

# ===== Scenario B: private-to-private cross-calls within same package =====

{
	package IntCross;
	use Sub::Private;

	sub new    { bless {}, shift }
	sub _step1 :Private { 'step1' }
	sub _step2 :Private { my $s = shift; 'step2+' . $s->_step1 }
	sub run    { (shift)->_step2 }
}

# ===== Scenario C: same sub name in two independent packages =====

{
	package IntAlpha;
	use Sub::Private;
	sub new     { bless {}, shift }
	sub _secret :Private { 'alpha_secret' }
	sub reveal  { (shift)->_secret }
}

{
	package IntBeta;
	use Sub::Private;
	sub new     { bless {}, shift }
	sub _secret :Private { 'beta_secret' }
	sub reveal  { (shift)->_secret }
}

{
	package IntThief;
	sub new     { bless {}, shift }
	sub steal_a { IntAlpha->new->_secret }
	sub steal_b { IntBeta->new->_secret  }
}

# ===== Scenario D: mixed attribute + declarative forms in one package =====

{
	package IntMixed;
	use Sub::Private qw(_decl_one);

	sub new        { bless {}, shift }
	sub _decl_one  { 'decl_one' }
	sub _attr_one  :Private { 'attr_one' }
	sub get_d1     { (shift)->_decl_one }
	sub get_a1     { (shift)->_attr_one }
}

{
	package IntMixedStranger;
	sub new    { bless {}, shift }
	sub try_d1 { IntMixed->new->_decl_one }
	sub try_a1 { IntMixed->new->_attr_one }
}

# ===== Scenario E: :Private used without per-package 'use Sub::Private' =====

{
	package IntNoUse;
	sub new        { bless {}, shift }
	sub _secret    :Private { 'confidential' }
	sub get_secret { (shift)->_secret }
}

{
	package IntNoUseStranger;
	sub new   { bless {}, shift }
	sub probe { IntNoUse->new->_secret }
}

# ===== Scenario F: stateful objects -- private sub manages mutable state =====

{
	package IntStateful;
	use Sub::Private;

	sub new   { bless { val => 0 }, shift }
	# _set is private: only IntStateful's own methods may change the value.
	sub _set  :Private { my ($s, $n) = @_; $s->{val} = $n; $s }
	sub set   { my ($s, $n) = @_; $s->_set($n) }
	sub get   { (shift)->{val} }
}

{
	package IntStatefulStranger;
	sub new    { bless {}, shift }
	sub hijack { my ($s, $target, $val) = @_; $target->_set($val) }
}

# ===== Scenario G: cross-class access -- OwnerA must not see OwnerB's private =====

{
	package IntOwnerA;
	use Sub::Private;
	sub new   { bless {}, shift }
	sub _priv :Private { 'A private' }
	sub own   { (shift)->_priv }
	# Deliberately tries to cross into OwnerB's private sub.
	sub steal { IntOwnerB->new->_priv }
}

{
	package IntOwnerB;
	use Sub::Private;
	sub new   { bless {}, shift }
	sub _priv :Private { 'B private' }
	sub own   { (shift)->_priv }
}

# ===== Scenario H: complex return values pass through the wrapper unchanged =====

{
	package IntComplex;
	use Sub::Private;
	sub new { bless {}, shift }
	# Returns a hashref with nested structure.
	sub _build :Private {
		my ($s, @items) = @_;
		return { count => scalar(@items), items => [@items] };
	}
	sub build { my ($s, @items) = @_; $s->_build(@items) }
}

{
	package IntComplexStranger;
	sub new { bless {}, shift }
	sub try { IntComplex->new->_build(1, 2, 3) }
}

# ===== Scenario I: collaborator -- owner called via a third-party worker =====

{
	package IntCollaborator;
	use Sub::Private;
	sub new     { bless {}, shift }
	sub _double :Private { my ($s, $n) = @_; $n * 2 }
	sub double  { my ($s, $n) = @_; $s->_double($n) }
}

{
	package IntWorker;
	# Does NOT use Sub::Private; calls only the PUBLIC interface of IntCollaborator.
	sub new  { bless {}, shift }
	sub work { my ($s, $c, $n) = @_; $c->double($n) }
}

{
	package IntWorkerStranger;
	sub new   { bless {}, shift }
	sub steal { my ($s, $c, $n) = @_; $c->_double($n) }
}

# ===== Scenario J: multiple private subs in one package, independent guards =====

{
	package IntMultiPriv;
	use Sub::Private;
	sub new     { bless {}, shift }
	sub _alpha  :Private { 'alpha' }
	sub _beta   :Private { 'beta'  }
	sub get_a   { (shift)->_alpha }
	sub get_b   { (shift)->_beta  }
}

{
	package IntMultiPrivStranger;
	sub new        { bless {}, shift }
	sub steal_alpha { IntMultiPriv->new->_alpha }
	sub steal_beta  { IntMultiPriv->new->_beta  }
}

# -------------------------------------------------------------------
# Tests
# -------------------------------------------------------------------

diag "Running $SP integration tests (enforce mode)" if $ENV{TEST_VERBOSE};

# ===================================================================
# SECTION 1: Module load and public interface
# ===================================================================

subtest 'module loads and exposes expected public interface' => sub {
	plan tests => 4;

	is $Sub::Private::VERSION, $VERSION, '$VERSION matches expected';
	is $Sub::Private::BYPASS, 0, '$BYPASS default is 0';
	ok exists $Sub::Private::config{harness_bypass}, '%config has harness_bypass key';
	is $Sub::Private::config{harness_bypass}, 1, 'harness_bypass defaults to 1';
};

# ===================================================================
# SECTION 2: Basic OO class -- owner allows, subclass blocks, stranger blocks
# ===================================================================

# Verify that all fixture classes can be constructed via new().
subtest 'object construction: new() succeeds for all scenario classes' => sub {
	plan tests => 8;
	# new_ok verifies the constructor returns a blessed reference.
	new_ok 'IntFoo';
	new_ok 'IntFooChild';
	new_ok 'IntAlpha';
	new_ok 'IntBeta';
	new_ok 'IntThief';
	new_ok 'IntCross';
	new_ok 'IntStateful';
	new_ok 'IntNoUse';
};

subtest 'OO class: owner can call its own private sub' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	my $result;
	lives_ok { $result = IntFoo->new->call_helper }
		'IntFoo owner can call _helper';
	is $result, $config{helper_result}, 'correct return value';
};

# POD: "Subclasses do not inherit access: private means this package only."
subtest 'OO class: SUBCLASS is BLOCKED (private = owner only)' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	throws_ok { IntFooChild->new->try_helper }
		qr/_helper\(\) is a private subroutine of IntFoo/,
		'subclass blocked from parent private sub';
};

subtest 'OO class: stranger is blocked with canonical message' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	throws_ok {
		my $vet = bless [IntFoo->new], 'IntVet';
		$vet->probe;
	} qr/private subroutine/, 'stranger blocked';

	# Exact message format: "NAME() is a private subroutine of PKG and cannot be called from PKG"
	my $err;
	eval { my $vet = bless [IntFoo->new], 'IntVet'; $vet->probe };
	$err = $@;
	like $err, qr/and cannot be called from IntVet/,
		'error message names the external caller';
};

# ===================================================================
# SECTION 3: Cross-private calls (private-to-private in same package)
# ===================================================================

subtest 'cross-private: private sub can call sibling private sub' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	my $result;
	lives_ok { $result = IntCross->new->run }
		'_step2 (private) can call _step1 (private) in same package';
	is $result, 'step2+step1', 'chained private result correct';
};

# ===================================================================
# SECTION 4: Concurrent instances -- independent enforcement per package
# ===================================================================

subtest 'concurrent instances: N objects of the same class enforce independently' => sub {
	my $n = $config{n_instances};
	plan tests => $n * 2;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;
	diag "Creating $n IntFoo instances" if $ENV{TEST_VERBOSE};

	my @objs = map { IntFoo->new } 1 .. $n;
	for my $i (0 .. $#objs) {
		my $obj = $objs[$i];
		lives_ok { $obj->call_helper } "instance $i: owner call lives";
		throws_ok { IntThief->new->steal_a }
			qr/private subroutine/, "instance $i: thief still blocked";
	}
};

# Mix three different package types concurrently to verify no cross-contamination.
subtest 'concurrent instances: mixed-type objects enforce independently' => sub {
	plan tests => 6;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;
	diag 'Testing IntAlpha, IntBeta, IntCross concurrently' if $ENV{TEST_VERBOSE};

	my @alphas = map { IntAlpha->new } 1 .. 3;
	my @betas  = map { IntBeta->new  } 1 .. 3;
	my @cross  = map { IntCross->new } 1 .. 3;

	# Each alpha should reveal its own value.
	lives_ok { $alphas[0]->reveal } 'alpha instance reveals correctly';

	# Each beta should reveal its own value.
	lives_ok { $betas[0]->reveal } 'beta instance reveals correctly';

	# Each cross should run its chained private calls.
	lives_ok { $cross[0]->run } 'cross instance runs correctly';

	# Thief must be blocked regardless of how many legitimate objects exist.
	throws_ok { IntThief->new->steal_a }
		qr/private subroutine/, 'thief blocked from IntAlpha (concurrent)';
	throws_ok { IntThief->new->steal_b }
		qr/private subroutine/, 'thief blocked from IntBeta (concurrent)';
	throws_ok { IntFooChild->new->try_helper }
		qr/private subroutine/, 'subclass blocked (concurrent)';
};

subtest 'two packages with same sub name enforce independently' => sub {
	plan tests => 4;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	my ($ra, $rb);
	lives_ok { $ra = IntAlpha->new->reveal } 'IntAlpha owner can call _secret';
	lives_ok { $rb = IntBeta->new->reveal  } 'IntBeta owner can call _secret';
	is $ra, 'alpha_secret', 'IntAlpha::_secret returns correct value';
	is $rb, 'beta_secret',  'IntBeta::_secret returns correct value';
};

subtest 'thief blocked from both independent packages' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	throws_ok { IntThief->new->steal_a }
		qr/_secret\(\) is a private subroutine of IntAlpha/,
		'thief blocked from IntAlpha::_secret';
	throws_ok { IntThief->new->steal_b }
		qr/_secret\(\) is a private subroutine of IntBeta/,
		'thief blocked from IntBeta::_secret';
};

# ===================================================================
# SECTION 5: Mixed attribute + declarative forms
# ===================================================================

subtest 'mixed forms: owner can call both declarative and attribute private subs' => sub {
	plan tests => 3;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;
	diag 'Testing mixed :Private and declarative import() in one package' if $ENV{TEST_VERBOSE};

	my $obj = new_ok 'IntMixed';
	lives_ok { $obj->get_d1 } 'declarative _decl_one accessible from owner';
	lives_ok { $obj->get_a1 } 'attribute _attr_one accessible from owner';
};

subtest 'mixed forms: stranger blocked from both' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	throws_ok { IntMixedStranger->new->try_d1 }
		qr/private subroutine/, 'stranger blocked from declarative _decl_one';
	throws_ok { IntMixedStranger->new->try_a1 }
		qr/private subroutine/, 'stranger blocked from attribute _attr_one';
};

# ===================================================================
# SECTION 6: UNIVERSAL registration (no per-package use)
# ===================================================================

subtest 'UNIVERSAL registration: :Private works without per-package use' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	my $result;
	lives_ok { $result = IntNoUse->new->get_secret }
		'owner access works without per-package "use Sub::Private"';
	is $result, 'confidential', 'correct return value';
};

subtest 'UNIVERSAL registration: stranger still blocked' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	throws_ok { IntNoUseStranger->new->probe }
		qr/private subroutine/, 'stranger blocked even without per-package use';
};

# ===================================================================
# SECTION 7: Moo integration
# ===================================================================

subtest 'Moo integration test' => sub {
	test_needs 'Moo';

	{
		package IntMooBase;
		use Moo;
		use Sub::Private qw(_moo_secret);

		sub _moo_secret { 'moo secret' }
		sub get_secret  { (shift)->_moo_secret }
	}

	{
		package IntMooStranger;
		sub new   { bless {}, shift }
		sub probe { IntMooBase->new->_moo_secret }
	}

	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;
	diag 'Testing Sub::Private + Moo integration' if $ENV{TEST_VERBOSE};

	my $obj = new_ok 'IntMooBase';
	my $result;
	lives_ok { $result = $obj->get_secret }
		'Moo: owner can call declarative-wrapped private sub';
	is $result, 'moo secret', 'Moo: correct return value';

	throws_ok { IntMooStranger->new->probe }
		qr/private subroutine/, 'Moo: stranger blocked from wrapped sub';
};

# ===================================================================
# SECTION 8: Moose integration (skip if Moose not available)
# ===================================================================

subtest 'Moose integration test' => sub {
	test_needs 'Moose';

	{
		package IntMooseBase;
		use Moose;
		use Sub::Private qw(_moose_secret);

		sub _moose_secret { 'moose secret' }
		sub get_secret    { (shift)->_moose_secret }
	}

	{
		package IntMooseStranger;
		sub new   { bless {}, shift }
		sub probe { IntMooseBase->new->_moose_secret }
	}

	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;
	diag 'Testing Sub::Private + Moose integration' if $ENV{TEST_VERBOSE};

	my $obj = new_ok 'IntMooseBase';
	my $result;
	lives_ok { $result = $obj->get_secret }
		'Moose: owner can call declarative-wrapped private sub';
	is $result, 'moose secret', 'Moose: correct return value';

	throws_ok { IntMooseStranger->new->probe }
		qr/private subroutine/, 'Moose: stranger blocked from wrapped sub';
};

# ===================================================================
# SECTION 9: $BYPASS scope and %config across multiple active objects
# ===================================================================

subtest 'BYPASS=1 allows ALL active objects, restores cleanly' => sub {
	plan tests => 3;
	local $ENV{HARNESS_ACTIVE} = 0;

	{ local $Sub::Private::BYPASS = 1;
	  lives_ok { IntAlpha->new->reveal } 'alpha owner call lives under BYPASS=1';
	  lives_ok { IntBeta->new->reveal  } 'beta owner call lives under BYPASS=1'; }

	{ local $Sub::Private::BYPASS = 0;
	  throws_ok { IntThief->new->steal_a } qr/private subroutine/,
		'thief blocked again after BYPASS scope exits'; }
};

subtest 'import(): return value is the class name' => sub {
	plan tests => $have_returns ? 2 : 1;

	my $result = Sub::Private->import();
	is $result, $SP, 'import() with no args returns "Sub::Private"';
	returns_ok($result, { type => 'string' }, 'return satisfies string schema')
		if $have_returns;
};

# ===================================================================
# SECTION 10: Stateful objects -- private sub manages mutable state
# ===================================================================

# Verify that multiple instances of IntStateful maintain independent state
# and that the private sub is correctly guarded.
subtest 'stateful: multiple instances maintain independent state' => sub {
	plan tests => 6;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;
	diag 'Testing independent state across multiple IntStateful instances' if $ENV{TEST_VERBOSE};

	my $a = new_ok 'IntStateful';
	my $b = new_ok 'IntStateful';

	# Each starts at zero.
	is $a->get, $config{stateful_init}, 'instance a initial value';
	is $b->get, $config{stateful_init}, 'instance b initial value';

	# Mutate only instance a; b must be unaffected.
	$a->set($config{stateful_delta});
	is $a->get, $config{stateful_delta}, 'instance a updated to delta';
	is $b->get, $config{stateful_init},  'instance b unchanged after a is mutated';
};

subtest 'stateful: stranger blocked from private state mutation' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	my $target = IntStateful->new;
	$target->set($config{stateful_delta});

	# Stranger must not be able to call _set directly.
	throws_ok { IntStatefulStranger->new->hijack($target, 999) }
		qr/private subroutine/,
		'stranger blocked from calling _set directly';

	# State must be unchanged after the failed attempt.
	is $target->get, $config{stateful_delta},
		'state unchanged after blocked access attempt';
};

# ===================================================================
# SECTION 11: Cross-class access -- OwnerA must not see OwnerB's private
# ===================================================================

# Both IntOwnerA and IntOwnerB own private subs named _priv.  Owning a
# private sub in package A grants NO access to _priv in package B.
subtest 'cross-class: OwnerA blocked from OwnerB private sub' => sub {
	plan tests => 3;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;
	diag 'Testing that owning a private sub does not grant cross-class access' if $ENV{TEST_VERBOSE};

	# Each owner can call its own private sub.
	lives_ok { IntOwnerA->new->own } 'OwnerA can call its own _priv';
	lives_ok { IntOwnerB->new->own } 'OwnerB can call its own _priv';

	# OwnerA's steal() tries to call OwnerB->_priv -- must be blocked.
	throws_ok { IntOwnerA->new->steal }
		qr/_priv\(\) is a private subroutine of IntOwnerB/,
		'OwnerA blocked from IntOwnerB::_priv even though A owns its own private sub';
};

# ===================================================================
# SECTION 12: can() in enforce mode
# ===================================================================

# In enforce mode the wrapper IS in the symbol table, so can() returns it.
# But calling the wrapper from outside the owner package is still blocked.
# This contrasts with namespace mode where can() returns undef.
subtest 'enforce mode: can() returns wrapper, calling it from outside is still blocked' => sub {
	plan tests => 3;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;
	diag 'Testing can() behavior in enforce mode' if $ENV{TEST_VERBOSE};

	# In enforce mode the stash entry is the wrapper, not undef.
	my $code_ref = IntAlpha->can('_secret');
	ok defined($code_ref), 'can("_secret") returns the wrapper coderef in enforce mode';

	# Owner access via OO dispatch still works.
	lives_ok { IntAlpha->new->reveal }
		'owner OO dispatch still works when can() returns wrapper';

	# Calling the wrapper coderef directly from main is still blocked.
	throws_ok { $code_ref->(IntAlpha->new) }
		qr/private subroutine/,
		'calling wrapper coderef directly from main is still blocked';
};

# ===================================================================
# SECTION 13: Error recovery -- objects remain usable after a croak
# ===================================================================

# A croak during an unauthorised access must not corrupt object state or
# prevent subsequent legitimate calls on the same or other objects.
subtest 'error recovery: objects remain usable after unauthorised access croak' => sub {
	plan tests => 4;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	my $alpha = IntAlpha->new;
	my $thief = IntThief->new;

	# Trigger a croak via the thief.
	my $first_err;
	eval { $thief->steal_a };
	$first_err = $@;
	ok $first_err, 'first unauthorised access croaks';

	# The alpha object is untouched; its legitimate method still works.
	my $result;
	lives_ok { $result = $alpha->reveal }
		'IntAlpha object still usable after someone else croaked';
	is $result, $config{alpha_result}, 'correct value after error recovery';

	# A second unauthorised attempt also fails (wrapper is still in place).
	my $second_err;
	eval { $thief->steal_a };
	$second_err = $@;
	ok $second_err, 'second unauthorised access also croaks (wrapper still active)';
};

# ===================================================================
# SECTION 14: Complex return values pass through the wrapper unchanged
# ===================================================================

# The wrapper must not alter, flatten, or corrupt the return value of
# the underlying private sub.
subtest 'return value integrity: hashref with nested structure' => sub {
	plan tests => 3;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;
	diag 'Testing complex return value through enforce-mode wrapper' if $ENV{TEST_VERBOSE};

	my $obj = IntComplex->new;
	my $result;
	lives_ok { $result = $obj->build(qw(a b c)) }
		'owner can call through wrapper returning hashref';

	is $result->{count}, $config{complex_items},
		'hashref count field correct';
	is_deeply $result->{items}, [qw(a b c)],
		'hashref items array correct (deep equality)';
};

subtest 'return value integrity: stranger still blocked' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	throws_ok { IntComplexStranger->new->try }
		qr/private subroutine/, 'stranger blocked from private builder';
};

# ===================================================================
# SECTION 15: Delegation through a third-party worker
# ===================================================================

# IntWorker calls only IntCollaborator's PUBLIC interface (double()).
# double() internally calls the private _double().  This should work
# because the call to _double originates from IntCollaborator's own code.
subtest 'delegation: third-party worker succeeds via public interface' => sub {
	plan tests => 3;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;
	diag 'Testing that delegation through public API works end-to-end' if $ENV{TEST_VERBOSE};

	my $collab = new_ok 'IntCollaborator';
	my $worker = new_ok 'IntWorker';

	# Worker calls collab's PUBLIC method double(), which internally uses _double().
	# The call to _double originates from IntCollaborator, so it is allowed.
	is $worker->work($collab, 7), 14,
		'result flows correctly: worker -> double (public) -> _double (private)';
};

subtest 'delegation: direct private access from worker is blocked' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	throws_ok { IntWorkerStranger->new->steal(IntCollaborator->new, 7) }
		qr/private subroutine/, 'worker stranger blocked from calling _double directly';
};

# ===================================================================
# SECTION 16: Multiple private subs in one package -- independent guards
# ===================================================================

subtest 'multi-private: each sub has its own independent guard' => sub {
	plan tests => 4;
	local $ENV{HARNESS_ACTIVE}  = 0;
	local $Sub::Private::BYPASS = 0;

	my $obj = IntMultiPriv->new;
	# Owner can call each private sub via its public accessor.
	is $obj->get_a, 'alpha', 'owner: _alpha returns correct value';
	is $obj->get_b, 'beta',  'owner: _beta returns correct value';

	# Stranger is blocked from each independently.
	throws_ok { IntMultiPrivStranger->new->steal_alpha }
		qr/private subroutine/, 'stranger blocked from _alpha';
	throws_ok { IntMultiPrivStranger->new->steal_beta }
		qr/private subroutine/, 'stranger blocked from _beta';
};

# ===================================================================
# SECTION 17: spy verification (if Test::Mockingbird available)
# ===================================================================

if ($have_mockingbird) {
	# Verify croak is called with the canonical message on unauthorised access.
	subtest 'spy: croak called exactly once per unauthorised access' => sub {
		plan tests => 3;
		local $ENV{HARNESS_ACTIVE}  = 0;
		local $Sub::Private::BYPASS = 0;

		my $spy = Test::Mockingbird::spy('Sub::Private::croak');
		eval { IntThief->new->steal_a };

		my @calls = $spy->();
		is scalar(@calls), 1, 'croak called exactly once per unauthorised access';

		my $msg = $calls[0][1];
		like $msg, qr/_secret\(\) is a private subroutine of IntAlpha/,
			'croak message contains sub-name and owner';
		like $msg, qr/cannot be called from IntThief/,
			'croak message contains the caller package';

		Test::Mockingbird::restore_all();
	};

	# Verify croak is NOT called when the owner accesses legitimately.
	subtest 'spy: croak NOT called for legitimate owner access' => sub {
		plan tests => 2;
		local $ENV{HARNESS_ACTIVE}  = 0;
		local $Sub::Private::BYPASS = 0;

		my $spy = Test::Mockingbird::spy('Sub::Private::croak');
		my $result;
		lives_ok { $result = IntAlpha->new->reveal } 'owner access succeeds';

		my @calls = $spy->();
		is scalar(@calls), 0, 'croak was NOT called for legitimate owner access';

		Test::Mockingbird::restore_all();
	};

	# Verify croak count accumulates correctly across multiple violations.
	subtest 'spy: croak count matches number of violations' => sub {
		plan tests => 2;
		local $ENV{HARNESS_ACTIVE}  = 0;
		local $Sub::Private::BYPASS = 0;

		my $spy = Test::Mockingbird::spy('Sub::Private::croak');

		# Two separate violations.
		eval { IntThief->new->steal_a };
		eval { IntThief->new->steal_b };

		my @calls = $spy->();
		is scalar(@calls), 2, 'croak called once per violation (2 total)';

		# Sandwiched owner calls must not inflate the count.
		IntAlpha->new->reveal;
		IntBeta->new->reveal;
		@calls = $spy->();
		is scalar(@calls), 2, 'croak count unchanged after legitimate owner access';

		Test::Mockingbird::restore_all();
	};

	# Verify validate_strict is called during declarative import().
	subtest 'spy: validate_strict called per sub name during import()' => sub {
		plan tests => 1;
		diag 'Spying on validate_strict during declarative import()' if $ENV{TEST_VERBOSE};

		my $spy = Test::Mockingbird::spy('Sub::Private::validate_strict');

		{
			package IntSpyImport;
			sub _x { 1 }
			sub _y { 2 }
			Sub::Private->import('_x', '_y');
		}

		my @calls = $spy->();
		ok scalar(@calls) >= 2,
			'validate_strict called at least once per sub name during import()';

		Test::Mockingbird::restore_all();
	};
}

done_testing;
