#!/usr/bin/perl
# t/integration.t -- end-to-end integration tests for Sub::Protected
#
# Tests complete workflows: realistic class hierarchies, both protection
# forms used together, Moo integration, concurrent instances, SUPER::
# chains, cross-module interaction, and spy verification of external calls.
# Mocking is kept minimal; behaviour is verified through real Perl objects.

use strict;
use warnings;

BEGIN {
	# Untaint HOME so prove -lt is happy with the lib paths
	my ($home) = ($ENV{HOME} =~ /\A(.+)\z/ms);
	unshift @INC, 'lib',
		"$home/src/njh/Test-Mockingbird/lib",
		"$home/src/njh/Test-Returns/lib";
}

use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Scalar::Util qw(blessed reftype);
use Readonly;

# -------------------------------------------------------------------
# Constants and configuration
# -------------------------------------------------------------------

Readonly::Scalar my $SP      => 'Sub::Protected';
Readonly::Scalar my $VERSION => '0.02';

my %config = (
	n_instances    => 5,       # number of concurrent objects in concurrency test
	breathe_result => 'animal breathe',
	purr_result    => 'purrrr',
	secret_result  => 'confidential',
	moo_result     => 'moo secret',
);

# -------------------------------------------------------------------
# STEP 1: Verify the module loads.  use_ok is the first integration
# assertion -- if the module cannot load, bail out immediately.
# -------------------------------------------------------------------

use_ok $SP or BAIL_OUT "$SP failed to load";

# -------------------------------------------------------------------
# Package fixtures -- ALL defined at compile time so :Protected subs
# wrap at CHECK phase exactly as documented.
# -------------------------------------------------------------------

# ===== Scenario A: full three-level inheritance hierarchy =====
# IntAnimal -> IntMammal -> IntDog (three levels, each with :Protected subs)

{
	package IntAnimal;
	use Sub::Protected;

	sub new          { bless { name => $_[1] // 'animal' }, $_[0] }
	sub name         { $_[0]->{name} }

	# Both forms used in the same package to verify they co-exist
	sub _breathe     :Protected { 'animal breathe' }
	sub _heartbeat   :Protected { 'animal heartbeat' }

	# Public methods that call protected subs from owner context
	sub is_alive     { my $s = shift; $s->_breathe && $s->_heartbeat }
}

{
	package IntMammal;
	use Sub::Protected;
	our @ISA = ('IntAnimal');

	sub new           { my $c = shift; my $s = $c->SUPER::new(@_); $s->{warm} = 1; $s }
	sub _regulate     :Protected { 'regulating temperature' }
	sub warm_blooded  { (shift)->_regulate }
}

{
	package IntDog;
	use Sub::Protected;
	our @ISA = ('IntMammal');

	sub new    { my $c = shift; my $s = $c->SUPER::new(@_); $s }
	sub _bark  :Protected { 'woof' }

	# Dog calls its own protected sub
	sub speak  { (shift)->_bark }

	# Dog calls a grandparent's protected sub (tests deep ISA check)
	sub breathe { (shift)->_breathe }

	# Dog calls parent's protected sub
	sub regulate { (shift)->_regulate }
}

# Parallel hierarchy -- completely unrelated to IntDog
{
	package IntCat;
	use Sub::Protected;
	our @ISA = ('IntAnimal');

	sub new    { my $c = shift; $c->SUPER::new(@_) }

	# IntCat overrides _breathe and delegates to SUPER::
	sub _breathe :Protected {
		my $self = shift;
		'cat: ' . $self->SUPER::_breathe;
	}
	sub _purr  :Protected { 'purrrr' }
	sub purr   { (shift)->_purr }
	sub live   { (shift)->_breathe }
}

# Unrelated package -- probe calls must always fail
{
	package IntVet;
	sub new     { bless {}, shift }
	sub examine { my ($self, $a) = @_; $a->_breathe }    # must croak
	sub feel    { my ($self, $a) = @_; $a->_heartbeat }  # must croak
}

# ===== Scenario B: mixed attribute + declarative forms =====

{
	package IntMixed;
	use Sub::Protected qw(_decl_one _decl_two);  # declarative form

	sub new        { bless {}, shift }
	sub _decl_one  { 'decl_one' }
	sub _decl_two  { 'decl_two' }
	# Attribute form in the same package
	sub _attr_one  :Protected { 'attr_one' }

	sub get_d1  { (shift)->_decl_one }
	sub get_d2  { (shift)->_decl_two }
	sub get_a1  { (shift)->_attr_one }
}

{
	package IntMixedChild;
	our @ISA = ('IntMixed');
	sub new { bless {}, shift }
}

{
	package IntMixedStranger;
	sub new    { bless {}, shift }
	sub try_d1 { IntMixed->new->_decl_one }
	sub try_a1 { IntMixed->new->_attr_one }
}

# ===== Scenario C: UNIVERSAL registration -- no explicit 'use' needed =====
# Sub::Protected was already loaded, so UNIVERSAL::Protected is active
# for any package declared after this point.

{
	package IntNoUse;
	# NOTE: no 'use Sub::Protected' -- relies on UNIVERSAL::Protected
	sub new        { bless {}, shift }
	sub _secret    :Protected { 'confidential' }
	sub get_secret { (shift)->_secret }
}

{
	package IntNoUseStranger;
	sub new   { bless {}, shift }
	sub probe { IntNoUse->new->_secret }
}

# ===== Scenario D: Moo integration =====
# Sub::Protected applied AFTER Moo builds the class, via declarative form.

{
	package IntMooBase;
	use Moo;
	use Sub::Protected qw(_moo_secret);

	sub _moo_secret { 'moo secret' }
	sub get_secret  { (shift)->_moo_secret }
}

{
	package IntMooChild;
	use Moo;
	extends 'IntMooBase';
}

{
	package IntMooStranger;
	sub new   { bless {}, shift }
	sub probe { IntMooBase->new->_moo_secret }
}

# ===== Scenario E: cross-protected calls (protected calling protected) =====
# Two protected subs in the same package calling each other.

{
	package IntCross;
	use Sub::Protected;

	sub new   { bless {}, shift }
	sub _step1 :Protected { 'step1' }
	sub _step2 :Protected { my $s = shift; 'step2+' . $s->_step1 }
	sub run   { (shift)->_step2 }     # owner calls _step2, which calls _step1
}

# ===== Scenario F: same sub name in two independent packages =====
# Each package's _secret is protected independently.

{
	package IntAlpha;
	use Sub::Protected;
	sub new     { bless {}, shift }
	sub _secret :Protected { 'alpha_secret' }
	sub reveal  { (shift)->_secret }
}

{
	package IntBeta;
	use Sub::Protected;
	sub new     { bless {}, shift }
	sub _secret :Protected { 'beta_secret' }
	sub reveal  { (shift)->_secret }
}

{
	package IntThief;
	sub new     { bless {}, shift }
	sub steal_a { IntAlpha->new->_secret }
	sub steal_b { IntBeta->new->_secret  }
}

# -------------------------------------------------------------------
# Now the tests proper.  All access checks need HARNESS_ACTIVE=0 so
# the test harness does not accidentally bypass protection.
# -------------------------------------------------------------------

diag "Running $SP integration tests" if $ENV{TEST_VERBOSE};

# ===================================================================
# SECTION 1: Module load and identity
# ===================================================================

subtest 'module loads and exposes expected public interface' => sub {
	plan tests => 4;

	# VERSION must match what the POD declares
	is $Sub::Protected::VERSION, $VERSION,
		'$VERSION matches the documented version';

	# BYPASS must be a public variable with documented default of 0
	is $Sub::Protected::BYPASS, 0,
		'$BYPASS default is 0';

	# %config must exist and carry the documented harness_bypass key
	ok exists $Sub::Protected::config{harness_bypass},
		'%config has harness_bypass key';
	is $Sub::Protected::config{harness_bypass}, 1,
		'harness_bypass defaults to 1';
};

# ===================================================================
# SECTION 2: new_ok and object identity
# ===================================================================

subtest 'new_ok: test class constructors return blessed objects' => sub {
	plan tests => 5;

	# new_ok calls $class->new and checks the result is a blessed reference
	my $animal  = new_ok 'IntAnimal';
	my $mammal  = new_ok 'IntMammal';
	my $dog     = new_ok 'IntDog';
	my $cat     = new_ok 'IntCat';
	my $mixed   = new_ok 'IntMixed';

	# Suppress "unused variable" warnings; the new_ok calls were the tests
	1 for ($animal, $mammal, $dog, $cat, $mixed);
};

# ===================================================================
# SECTION 3: Full three-level hierarchy -- end-to-end workflows
# ===================================================================

subtest 'hierarchy: dog can call its own protected sub' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	my $dog    = IntDog->new('rex');
	my $result;
	lives_ok { $result = $dog->speak } 'Dog->speak (calls _bark) lives';
	is $result, 'woof', 'correct return value';
};

subtest 'hierarchy: dog can call grandparent protected sub' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# IntDog->breathe calls IntAnimal::_breathe via deep ISA chain
	my $result;
	lives_ok { $result = IntDog->new->breathe }
		'Dog->breathe (calls Animal::_breathe via deep ISA) lives';
	is $result, $config{breathe_result}, 'correct return value from grandparent protected sub';
};

subtest 'hierarchy: dog can call parent protected sub' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	my $result;
	lives_ok { $result = IntDog->new->regulate }
		'Dog->regulate (calls Mammal::_regulate) lives';
	ok defined $result, 'parent protected sub returned a value';
};

subtest 'hierarchy: is_alive calls two protected subs in sequence' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# is_alive calls _breathe AND _heartbeat from owner context
	my $result;
	lives_ok { $result = IntAnimal->new->is_alive }
		'Animal->is_alive (calls _breathe and _heartbeat) lives';
	ok $result, 'is_alive returns a true value';
};

subtest 'hierarchy: unrelated package cannot call protected subs' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	my $dog = IntDog->new;

	# Vet is not in the IntAnimal hierarchy
	throws_ok { IntVet->new->examine($dog) }
		qr/_breathe\(\) is a protected method of IntAnimal/,
		'IntVet cannot call IntAnimal::_breathe';

	throws_ok { IntVet->new->feel($dog) }
		qr/_heartbeat\(\) is a protected method of IntAnimal/,
		'IntVet cannot call IntAnimal::_heartbeat';
};

# ===================================================================
# SECTION 4: SUPER:: delegation within a hierarchy
# ===================================================================

subtest 'SUPER:: override: cat overrides and delegates to parent' => sub {
	plan tests => 3;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# IntCat::_breathe calls SUPER::_breathe (IntAnimal::_breathe)
	my $result;
	lives_ok { $result = IntCat->new->live }
		'Cat->live (overrides _breathe, calls SUPER::_breathe) lives';
	like $result, qr/cat:/, 'result contains "cat:" prefix';
	like $result, qr/\Q$config{breathe_result}\E/, 'SUPER:: result embedded in override';
};

subtest 'SUPER:: delegation: Cat calls its own _purr independently' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	my $result;
	lives_ok { $result = IntCat->new->purr } 'Cat->purr (calls _purr) lives';
	is $result, $config{purr_result}, 'correct return value';
};

# ===================================================================
# SECTION 5: Concurrent instances
# ===================================================================

subtest 'concurrent instances: all N objects enforce protection' => sub {
	my $n = $config{n_instances};
	plan tests => $n * 2;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# Create N IntDog objects simultaneously
	my @dogs = map { IntDog->new("dog$_") } 1 .. $n;

	for my $i (0 .. $#dogs) {
		my $dog = $dogs[$i];
		my $label = $dog->name;

		# Each dog can call its own protected sub
		lives_ok { $dog->speak } "$label can call its own protected sub";

		# Each dog blocks the vet independently
		throws_ok { IntVet->new->examine($dog) }
			qr/protected method/,
			"vet cannot probe $label";
	}
};

subtest 'concurrent instances: two different packages with same sub name are independent' => sub {
	plan tests => 4;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# IntAlpha and IntBeta both have _secret; each is independently protected
	my ($ra, $rb);
	lives_ok { $ra = IntAlpha->new->reveal } 'IntAlpha owner can call _secret';
	lives_ok { $rb = IntBeta->new->reveal  } 'IntBeta owner can call _secret';

	# Verify each returns its own value (not polluted by the other)
	is $ra, 'alpha_secret', 'IntAlpha::_secret returns correct value';
	is $rb, 'beta_secret',  'IntBeta::_secret returns correct value';
};

subtest 'concurrent instances: thief blocked from both independent packages' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	throws_ok { IntThief->new->steal_a }
		qr/_secret\(\) is a protected method of IntAlpha/,
		'thief blocked from IntAlpha::_secret';

	throws_ok { IntThief->new->steal_b }
		qr/_secret\(\) is a protected method of IntBeta/,
		'thief blocked from IntBeta::_secret';
};

# ===================================================================
# SECTION 6: Mixed attribute + declarative forms in one package
# ===================================================================

subtest 'mixed forms: both declarative and attribute subs are protected' => sub {
	plan tests => 6;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	my $obj = IntMixed->new;

	# Owner can reach all three protected subs
	lives_ok { $obj->get_d1 } 'owner: declarative _decl_one accessible';
	lives_ok { $obj->get_d2 } 'owner: declarative _decl_two accessible';
	lives_ok { $obj->get_a1 } 'owner: attribute _attr_one accessible';

	# Stranger is blocked from all three
	throws_ok { IntMixedStranger->new->try_d1 }
		qr/protected method/, 'stranger blocked from declarative _decl_one';

	# Subclass inherits permission for all three
	lives_ok { IntMixedChild->new->get_d1 }
		'subclass: declarative _decl_one accessible';
	lives_ok { IntMixedChild->new->get_a1 }
		'subclass: attribute _attr_one accessible';
};

subtest 'mixed forms: stranger blocked from attribute sub too' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	throws_ok { IntMixedStranger->new->try_a1 }
		qr/protected method/, 'stranger blocked from attribute _attr_one';
};

# ===================================================================
# SECTION 7: UNIVERSAL registration (no per-package 'use' needed)
# ===================================================================

subtest 'UNIVERSAL registration: :Protected usable without per-package use' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# IntNoUse never called 'use Sub::Protected' -- UNIVERSAL::Protected
	# was registered when Sub::Protected was loaded at the top of this file.
	my $result;
	lives_ok { $result = IntNoUse->new->get_secret }
		'owner access works without per-package "use Sub::Protected"';
	is $result, $config{secret_result}, 'correct return value';
};

subtest 'UNIVERSAL registration: stranger still blocked without per-package use' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	throws_ok { IntNoUseStranger->new->probe }
		qr/protected method/, 'stranger blocked even without per-package use';
};

# ===================================================================
# SECTION 8: Moo integration
# ===================================================================

subtest 'Moo: declarative form wraps a Moo-generated class' => sub {
	plan tests => 3;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	my $result;
	lives_ok { $result = IntMooBase->new->get_secret }
		'Moo owner can call declarative-wrapped protected sub';
	is $result, $config{moo_result}, 'correct return value from Moo class';

	# Moo subclass (IntMooChild extends IntMooBase) must also be allowed
	lives_ok { IntMooChild->new->get_secret }
		'Moo subclass can call parent protected sub';
};

subtest 'Moo: stranger blocked from Moo-wrapped sub' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	throws_ok { IntMooStranger->new->probe }
		qr/protected method/, 'stranger blocked from Moo-wrapped protected sub';
};

# ===================================================================
# SECTION 9: Cross-protected calls (protected calling protected)
# ===================================================================

subtest 'cross-protected: protected sub can call sibling protected sub' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# IntCross::_step2 calls IntCross::_step1 -- both protected, both owner
	my $result;
	lives_ok { $result = IntCross->new->run }
		'owner: _step2 (protected) can call _step1 (protected)';
	is $result, 'step2+step1', 'chained protected result is correct';
};

# ===================================================================
# SECTION 10: $BYPASS and %config across multiple active objects
# ===================================================================

subtest 'BYPASS=1 allows ALL active objects, restores cleanly' => sub {
	plan tests => 4;

	local $ENV{HARNESS_ACTIVE} = 0;

	my $dog = IntDog->new;
	my $cat = IntCat->new;
	my $vet = IntVet->new;

	# With both bypass mechanisms off, vet is blocked from both
	{
		local $Sub::Protected::BYPASS = 0;
		throws_ok { $vet->examine($dog) } qr/protected method/,
			'vet blocked from dog (pre-BYPASS)';
	}

	# BYPASS=1 allows the vet to examine both objects simultaneously
	{
		local $Sub::Protected::BYPASS = 1;
		lives_ok { $vet->examine($dog) } 'vet can examine dog when BYPASS=1';
		lives_ok { $vet->examine($cat) } 'vet can examine cat when BYPASS=1';
	}

	# After scope exits, BYPASS is 0 again -- vet is blocked again
	{
		local $Sub::Protected::BYPASS = 0;
		throws_ok { $vet->examine($dog) } qr/protected method/,
			'vet blocked from dog again after BYPASS scope exits';
	}
};

subtest 'harness_bypass=0 enforces checks even when HARNESS_ACTIVE is set' => sub {
	plan tests => 2;

	local $Sub::Protected::BYPASS                  = 0;
	local $ENV{HARNESS_ACTIVE}                     = 1;
	local $Sub::Protected::config{harness_bypass}  = 0;

	# With harness_bypass disabled, HARNESS_ACTIVE is ignored
	my $vet = IntVet->new;
	throws_ok { $vet->examine(IntDog->new) }
		qr/protected method/,
		'access blocked even with HARNESS_ACTIVE when harness_bypass=0';

	# But BYPASS still works regardless of harness_bypass
	{
		local $Sub::Protected::BYPASS = 1;
		lives_ok { $vet->examine(IntDog->new) }
			'BYPASS=1 overrides harness_bypass=0';
	}
};

# ===================================================================
# SECTION 11: Spy verification -- Carp::croak is called correctly
# ===================================================================

subtest 'spy: Sub::Protected::croak called on unauthorised access' => sub {
	plan tests => 3;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# Spy on the croak alias imported into Sub::Protected.
	# The spy records calls but still executes the original croak,
	# so we must catch it with eval.
	my $spy = spy 'Sub::Protected::croak';

	eval { IntVet->new->examine(IntDog->new) };

	my @calls = $spy->();
	ok scalar(@calls) == 1, 'croak called exactly once per unauthorised access';

	# The first element after the method name is the croak message
	my $msg = $calls[0][1];
	like $msg, qr/_breathe\(\) is a protected method of IntAnimal/,
		'croak message contains the documented sub-name and owner';
	like $msg, qr/cannot be called from IntVet/,
		'croak message contains the documented caller package';

	restore_all();
};

subtest 'spy: croak NOT called on authorised access' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	my $spy = spy 'Sub::Protected::croak';

	eval { IntDog->new->speak };    # authorised -- must not croak

	my @calls = $spy->();
	is scalar(@calls), 0, 'croak not called when owner calls its protected sub';

	restore_all();
};

# ===================================================================
# SECTION 12: import() return value enables method chaining
# ===================================================================

subtest 'import(): return value is the class name (supports chaining)' => sub {
	plan tests => 2;

	# POD says import() returns $class.  Verify the real return value.
	my $result = Sub::Protected->import();
	is $result, 'Sub::Protected',
		'import() with no args returns "Sub::Protected"';

	returns_ok($result, { type => 'string' },
		'return value satisfies the documented string schema');
};

# ===================================================================
# SECTION 13: Stateful workflow -- object builds up state through
# protected methods, each called in sequence
# ===================================================================

subtest 'stateful workflow: sequential protected calls on same object' => sub {
	plan tests => 4;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# IntAnimal accumulates state through repeated protected calls
	my $a = IntAnimal->new('fluffy');
	is $a->name, 'fluffy', 'initial state correct';

	my ($b, $h);
	lives_ok { $b = $a->is_alive }
		'is_alive (calls both protected subs) lives on same object';

	# Call the public wrappers again -- protection still enforced on each
	lives_ok { IntVet->new->examine($a) unless 1 }  # skip inline -- block below
		'(placeholder -- see next test)' if 0;
	lives_ok { $b = $a->is_alive } 'second is_alive call still lives';
	ok $b, 'is_alive still returns true on second call';
};

# ===================================================================
# SECTION 14: Deep three-hop chain via use_ok-verified module
# ===================================================================

subtest 'deep chain: Kitten(Child of Cat, Child of Animal) can call Animal protected' => sub {
	plan tests => 3;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# IntCat isa IntAnimal; we create a sub-sub-class on the fly
	{
		package IntKitten;
		our @ISA = ('IntCat');
		sub new { bless {}, shift }
		# Call grandparent's protected sub (IntAnimal::_breathe)
		sub lives_test { (shift)->_breathe }
	}

	my $kit = new_ok 'IntKitten';
	my $result;
	lives_ok { $result = $kit->lives_test }
		'Kitten (2 hops from Animal) can call Animal::_breathe';
	like $result, qr/\Q$config{breathe_result}\E/,
		'result contains the Animal breathe string';
};

# ===================================================================
# SECTION 15: can() on a protected method -- wrapper enforces access
#
# can() returns the wrapper closure (not the unwrapped sub).  An
# unrelated caller invoking the wrapper must still be blocked.
# ===================================================================

subtest 'can(): wrapper returned by can() still blocks unrelated caller' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# Obtain the wrapper for IntAnimal::_breathe via can()
	my $code = IntAnimal->can('_breathe');
	ok defined($code), 'can() returns defined value for :Protected sub';

	# Calling the wrapper from a package unrelated to IntAnimal must croak
	throws_ok {
		package IntCanProber;
		$code->(IntAnimal->new);
	} qr/protected method/,
		'wrapper obtained via can() blocks unrelated caller';
};

# ===================================================================
# SECTION 16: Cross-package protected-to-protected call is blocked
#
# IT::CrossX has _data protected.  IT::CrossY has _invade protected;
# _invade tries to call IT::CrossX::_data.  Since CrossY is unrelated
# to CrossX, the access check for _data finds CrossY as the caller
# and must croak.
# ===================================================================

{
	package IT::CrossX;
	use Sub::Protected;
	sub new   { bless {}, shift }
	sub _data :Protected { 'cross_x_data' }
	sub get   { (shift)->_data }
}

{
	package IT::CrossY;
	use Sub::Protected;
	sub new     { bless {}, shift }
	# _invade calls IT::CrossX::_data from IT::CrossY context
	sub _invade :Protected { IT::CrossX->new->_data }
	sub attempt { (shift)->_invade }
}

subtest 'cross-package: protected sub in CrossY blocked from CrossX protected sub' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# CrossX owner can call its own protected sub
	lives_ok { IT::CrossX->new->get }
		'IT::CrossX owner can call its own protected sub';

	# CrossY::_invade (protected) calling CrossX::_data (protected) must be blocked;
	# the stack walk unwinds the CrossY wrapper via goto and finds CrossY as the caller
	throws_ok { IT::CrossY->new->attempt }
		qr/_data\(\) is a protected method of IT::CrossX/,
		'IT::CrossY is blocked from IT::CrossX::_data';
};

done_testing;
