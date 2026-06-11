#!/usr/bin/perl
# t/integration.t -- end-to-end integration tests for Sub::Abstract.
#
# Tests complete workflows: realistic class hierarchies, both usage forms
# together, multi-level inheritance, re-abstraction, concurrent instances,
# composition patterns, and spy verification of external calls.
# Mocking is kept minimal; behaviour is verified through real Perl objects.

use strict;
use warnings;

# Taint-safe INC manipulation so prove -lt can find local dev copies.
BEGIN {
	my ($home) = ($ENV{HOME} =~ /\A(.+)\z/ms);
	unshift @INC, 'lib',
		"$home/src/njh/Test-Mockingbird/lib",
		"$home/src/njh/Test-Returns/lib";
}

use Test::Most;
use Test::Needs;
use Test::Returns;
use Test::Mockingbird;
use Scalar::Util qw(blessed reftype);
use Readonly;

# -------------------------------------------------------------------
# Constants -- avoid magic strings and magic numbers throughout
# -------------------------------------------------------------------

Readonly::Scalar my $SA      => 'Sub::Abstract';
Readonly::Scalar my $VERSION => '0.01';

# Test configuration: expected return values, iteration counts, etc.
my %config = (
	n_instances    => 5,
	dog_speak      => 'Woof',
	cat_speak      => 'Meow',
	cat_eat        => 'nom nom',
	tri_area       => 6,
	tri_sides      => 3,
	counter_steps  => 5,
	html_result    => '<p>hello</p>',
	proc_result    => 'processed',
	validate_result => 'valid',
	plugin1_result => 'plugin1 active',
	plugin2_result => 'plugin2 active',
);

# -------------------------------------------------------------------
# Module load check -- bail immediately if the module cannot load.
# use_ok verifies that the module loads AND exports correctly.
# -------------------------------------------------------------------

use_ok 'Sub::Abstract' or BAIL_OUT 'Sub::Abstract failed to load';

# -------------------------------------------------------------------
# Package fixtures -- ALL defined at compile time so :Abstract subs
# are wrapped at CHECK phase exactly as documented.
# All fixture packages are prefixed IT:: to avoid collision with other
# test files.
# -------------------------------------------------------------------

# ===== Scenario A: basic single-level abstract enforcement =====
# Two abstract methods; Dog partially implements; Cat fully implements;
# Blob implements nothing.

{
	package IT::Animal;
	use Sub::Abstract;

	sub new   { bless {}, shift }
	sub speak :Abstract { }    # stub required for Attribute::Handlers
	sub eat   :Abstract { }    # second abstract method in same package
}

# Dog implements speak() only -- partial implementation.
{
	package IT::Dog;
	our @ISA = ('IT::Animal');
	sub new   { bless {}, shift }
	sub speak { 'Woof' }    # satisfies the abstract contract for speak
	# eat is intentionally NOT implemented
}

# Cat implements both abstract methods -- full implementation.
{
	package IT::Cat;
	our @ISA = ('IT::Animal');
	sub new   { bless {}, shift }
	sub speak { 'Meow' }
	sub eat   { 'nom nom' }
}

# Blob implements neither -- every abstract call must croak.
{
	package IT::Blob;
	our @ISA = ('IT::Animal');
	sub new { bless {}, shift }
}

# ===== Scenario B: three-level inheritance =====
# Shape abstracts area() and perimeter().
# Polygon extends Shape without implementing them, adds abstract sides().
# Triangle is the concrete leaf that implements all three.

{
	package IT::Shape;
	use Sub::Abstract;
	sub new       { bless {}, shift }
	sub area      :Abstract { }
	sub perimeter :Abstract { }
}

{
	package IT::Polygon;
	use Sub::Abstract;
	our @ISA = ('IT::Shape');
	sub new   { bless {}, shift }
	# inherits abstract area() and perimeter() -- still unimplemented here
	sub sides :Abstract { }    # adds a new abstract method
}

{
	package IT::Triangle;
	our @ISA = ('IT::Polygon');
	sub new       { bless {}, shift }
	sub area      { 6  }
	sub perimeter { 12 }
	sub sides     { 3  }
}

# BrokenPolygon: extends Polygon but implements nothing.
{
	package IT::BrokenPolygon;
	our @ISA = ('IT::Polygon');
	sub new { bless {}, shift }
}

# ===== Scenario C: mixed attribute + declarative forms =====
# Vehicle uses the declarative form for stop() and the attribute form for go().
# Both must enforce independently.

{
	package IT::Vehicle;
	use Sub::Abstract qw(stop);    # declarative form -- no stub needed
	sub new { bless {}, shift }
	sub go  :Abstract { }          # attribute form -- stub required
}

{
	package IT::Car;
	our @ISA = ('IT::Vehicle');
	sub new  { bless {}, shift }
	sub go   { 'vroom'   }
	sub stop { 'screech' }
}

# Bike: implements go (attribute form) but NOT stop (declarative form).
{
	package IT::Bike;
	our @ISA = ('IT::Vehicle');
	sub new { bless {}, shift }
	sub go  { 'pedal' }
}

# ===== Scenario D: re-abstraction =====
# Base declares process() abstract.
# Middle implements process() but re-declares validate() as abstract.
# Concrete implements validate().  PartialMiddle does not.

{
	package IT::Base;
	use Sub::Abstract;
	sub new     { bless {}, shift }
	sub process :Abstract { }
}

{
	package IT::Middle;
	use Sub::Abstract;
	our @ISA = ('IT::Base');
	sub new     { bless {}, shift }
	sub process  { 'processed' }     # satisfies IT::Base::process
	sub validate :Abstract { }       # new abstract method declared here
}

{
	package IT::Concrete;
	our @ISA = ('IT::Middle');
	sub new      { bless {}, shift }
	sub validate { 'valid' }         # satisfies IT::Middle::validate
}

{
	package IT::PartialMiddle;
	our @ISA = ('IT::Middle');
	sub new { bless {}, shift }
	# validate intentionally NOT implemented
}

# ===== Scenario E: independent packages with the same method name =====
# Plugin1 and Plugin2 are unrelated -- their activate() wrappers are
# installed independently.  Implementing one does not satisfy the other.

{
	package IT::Plugin1;
	use Sub::Abstract;
	sub new      { bless {}, shift }
	sub activate :Abstract { }
}

{
	package IT::Plugin2;
	use Sub::Abstract;
	sub new      { bless {}, shift }
	sub activate :Abstract { }     # same name, different owner -- independent
}

{
	package IT::Plugin1Impl;
	our @ISA = ('IT::Plugin1');
	sub new      { bless {}, shift }
	sub activate { 'plugin1 active' }
}

{
	package IT::Plugin2Impl;
	our @ISA = ('IT::Plugin2');
	sub new      { bless {}, shift }
	sub activate { 'plugin2 active' }
}

# ===== Scenario F: stateful OO with abstract reset() =====
# Counter manages shared state; reset() is abstract so subclasses define
# the reset semantics.  Multiple instances must be fully independent.

{
	package IT::Counter;
	use Sub::Abstract;

	sub new       { bless { count => 0 }, shift }
	sub reset     :Abstract { }                    # how to reset is the subclass's concern
	sub increment { my $s = shift; $s->{count}++; $s }
	sub count     { (shift)->{count} }
}

{
	package IT::ResettableCounter;
	our @ISA = ('IT::Counter');
	sub new   { bless { count => 0 }, shift }
	sub reset { my $s = shift; $s->{count} = 0; $s }
}

{
	package IT::BrokenCounter;
	our @ISA = ('IT::Counter');
	sub new { bless { count => 0 }, shift }
	# reset NOT implemented
}

# ===== Scenario G: composition / dependency injection =====
# Formatter is an abstract "interface": any class that composes it must
# implement format().  Printer delegates to a Formatter it receives.

{
	package IT::Formatter;
	use Sub::Abstract;
	sub new    { bless {}, shift }
	sub format :Abstract { }
}

{
	package IT::HtmlFormatter;
	our @ISA = ('IT::Formatter');
	sub new    { bless {}, shift }
	sub format { my ($s, $text) = @_; "<p>$text</p>" }
}

# Printer does NOT extend Formatter -- it uses one via composition.
{
	package IT::Printer;
	sub new      { bless { fmt => $_[1] }, $_[0] }
	sub print_it { my ($s, $text) = @_; $s->{fmt}->format($text) }
}

# ===== Scenario H: precise error-message verification =====
# Named is a minimal class used only to check the exact three-part
# error format documented in the POD.

{
	package IT::Named;
	use Sub::Abstract;
	sub new    { bless {}, shift }
	sub action :Abstract { }
}

{
	package IT::NamedImpl;
	our @ISA = ('IT::Named');
	sub new    { bless {}, shift }
	sub action { 'done' }
}

# ===== Scenario I: :Abstract without per-package 'use' =====
# Once Sub::Abstract is loaded (by any package), UNIVERSAL::Abstract is
# available in every package -- no per-package 'use Sub::Abstract' needed.

{
	package IT::NoUse;
	# No explicit 'use Sub::Abstract' here
	sub new    { bless {}, shift }
	sub run    :Abstract { }    # relies on UNIVERSAL::Abstract being globally installed
}

{
	package IT::NoUseImpl;
	our @ISA = ('IT::NoUse');
	sub new { bless {}, shift }
	sub run { 'ran' }
}

# ===== Scenario J: SUPER:: dispatch =====
# SuperCallSub provides a concrete render() that immediately delegates to
# SUPER::render(), which is the abstract wrapper in SuperCallBase.
# This exercises the path where the wrapper is reached via SUPER:: dispatch
# rather than directly through an unimplemented subclass.

{
	package IT::SuperCallBase;
	use Sub::Abstract;
	sub new    { bless {}, shift }
	sub render :Abstract { }
}

{
	package IT::SuperCallSub;
	our @ISA = ('IT::SuperCallBase');
	sub new    { bless {}, shift }
	# render IS defined (MRO finds it), but it explicitly calls SUPER::render,
	# which routes directly to IT::SuperCallBase::render (the abstract wrapper).
	sub render { my $self = shift; $self->SUPER::render(@_) }
}

# -------------------------------------------------------------------
# TESTS
# -------------------------------------------------------------------

diag "Starting $SA integration tests" if $ENV{TEST_VERBOSE};

# ===================================================================
# SECTION 1: Module load and public variables
# ===================================================================

subtest 'module: exposes documented public variables with correct defaults' => sub {
	plan tests => 4;

	# use_ok already ran at the top; here we check the documented public API
	is $Sub::Abstract::VERSION, $VERSION, '$VERSION matches documented version';
	is $Sub::Abstract::BYPASS, 0,         '$BYPASS default is 0';
	ok exists $Sub::Abstract::config{harness_bypass},
		'%config has the documented harness_bypass key';
	is $Sub::Abstract::config{harness_bypass}, 1,
		'harness_bypass defaults to 1';
};

# ===================================================================
# SECTION 2: Object construction
# ===================================================================

# Abstract base classes must be constructable -- the wrapper fires only
# when the abstract METHOD is called, not on object construction.
subtest 'object construction: new() succeeds for all fixture classes' => sub {
	plan tests => 13;

	# new_ok verifies the constructor returns a blessed reference of the right class
	new_ok 'IT::Animal';
	new_ok 'IT::Dog';
	new_ok 'IT::Cat';
	new_ok 'IT::Blob';
	new_ok 'IT::Shape';
	new_ok 'IT::Polygon';
	new_ok 'IT::Triangle';
	new_ok 'IT::Vehicle';
	new_ok 'IT::Car';
	new_ok 'IT::Counter';
	new_ok 'IT::ResettableCounter';
	new_ok 'IT::Formatter';
	new_ok 'IT::HtmlFormatter';
};

# ===================================================================
# SECTION 3: Basic single-level abstract enforcement
# ===================================================================

# Calling an abstract method directly on the base class must croak with
# the exact documented three-part message.
subtest 'base class: abstract method calls croak with documented message' => sub {
	plan tests => 3;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	diag 'IT::Animal::speak and IT::Animal::eat must croak' if $ENV{TEST_VERBOSE};

	throws_ok { IT::Animal->new->speak }
		qr/speak\(\) is an abstract method of IT::Animal and must be implemented by IT::Animal/,
		'IT::Animal::speak croaks with the full documented message';

	throws_ok { IT::Animal->new->eat }
		qr/eat\(\) is an abstract method of IT::Animal and must be implemented by IT::Animal/,
		'IT::Animal::eat croaks with the full documented message';

	# Error must always name the concrete invocant, not just the abstract owner
	throws_ok { IT::Blob->new->speak }
		qr/must be implemented by IT::Blob/,
		'error names IT::Blob as invocant when Blob has no implementation';
};

# Fully implementing subclass: the abstract wrapper in the base is
# never reached because Perl's MRO resolves to the concrete sub first.
subtest 'full implementation: all abstract methods work in concrete subclass' => sub {
	plan tests => 3;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	my $cat = new_ok 'IT::Cat';
	lives_and { is(IT::Cat->new->speak, $config{cat_speak}) }
		'IT::Cat::speak returns the implemented value';
	lives_and { is(IT::Cat->new->eat,   $config{cat_eat})   }
		'IT::Cat::eat returns the implemented value';
};

# Partial implementation: implemented method works; unimplemented croaks.
subtest 'partial implementation: implemented OK, unimplemented croaks' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# Dog implements speak() -- must not croak
	lives_and { is(IT::Dog->new->speak, $config{dog_speak}) }
		'IT::Dog::speak (implemented) returns the correct value';

	# Dog does NOT implement eat() -- must croak with the correct invocant
	throws_ok { IT::Dog->new->eat }
		qr/eat\(\) is an abstract method of IT::Animal and must be implemented by IT::Dog/,
		'IT::Dog::eat (not implemented) croaks with IT::Dog as invocant';
};

# No implementation at all: every abstract method call must croak.
subtest 'no implementation: all abstract methods croak for Blob' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	throws_ok { IT::Blob->new->speak }
		qr/speak\(\) is an abstract method of IT::Animal and must be implemented by IT::Blob/,
		'IT::Blob::speak croaks naming IT::Blob as the invocant';

	throws_ok { IT::Blob->new->eat }
		qr/eat\(\) is an abstract method of IT::Animal and must be implemented by IT::Blob/,
		'IT::Blob::eat croaks naming IT::Blob as the invocant';
};

# ===================================================================
# SECTION 4: Three-level inheritance
# ===================================================================

# The concrete leaf class must satisfy all abstract methods declared at
# any level of the hierarchy.
subtest 'three-level hierarchy: concrete leaf satisfies all abstract methods' => sub {
	plan tests => 4;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	diag 'IT::Triangle extends IT::Polygon extends IT::Shape' if $ENV{TEST_VERBOSE};

	my $tri = new_ok 'IT::Triangle';
	lives_and { is(IT::Triangle->new->area,  $config{tri_area})  } 'area() returns correct value';
	lives_and { is(IT::Triangle->new->sides, $config{tri_sides}) } 'sides() returns correct value';
	lives_ok  { IT::Triangle->new->perimeter } 'perimeter() works in concrete leaf';
};

# BrokenPolygon implements nothing -- every abstract method must croak,
# reporting the package where the wrapper was installed (the declaring owner).
subtest 'three-level hierarchy: uninimplemented abstract methods croak at all levels' => sub {
	plan tests => 3;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# area and perimeter were declared abstract in IT::Shape
	throws_ok { IT::BrokenPolygon->new->area }
		qr/area\(\) is an abstract method of IT::Shape and must be implemented by IT::BrokenPolygon/,
		'area() names IT::Shape (declaring owner) and IT::BrokenPolygon (invocant)';

	throws_ok { IT::BrokenPolygon->new->perimeter }
		qr/perimeter\(\) is an abstract method of IT::Shape/,
		'perimeter() names IT::Shape as declaring owner';

	# sides was declared abstract in IT::Polygon (one level lower)
	throws_ok { IT::BrokenPolygon->new->sides }
		qr/sides\(\) is an abstract method of IT::Polygon/,
		'sides() names IT::Polygon as declaring owner (not Shape)';
};

# ===================================================================
# SECTION 5: Mixed attribute + declarative forms in one class
# ===================================================================

subtest 'mixed forms: fully implementing subclass works for both forms' => sub {
	plan tests => 3;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	diag ':Abstract (attribute) and declarative qw(stop) in the same base class' if $ENV{TEST_VERBOSE};

	my $car = new_ok 'IT::Car';
	lives_ok { IT::Car->new->go   } 'go() (attribute form): satisfied by IT::Car';
	lives_ok { IT::Car->new->stop } 'stop() (declarative form): satisfied by IT::Car';
};

subtest 'mixed forms: partial implementation croaks for the unimplemented method' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# Bike implements go (attribute form) but not stop (declarative form)
	lives_ok  { IT::Bike->new->go   }
		'go() (attribute form) works for IT::Bike';
	throws_ok { IT::Bike->new->stop }
		qr/stop\(\) is an abstract method of IT::Vehicle/,
		'stop() (declarative form) still croaks for IT::Bike';
};

subtest 'mixed forms: base class enforces both forms' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	throws_ok { IT::Vehicle->new->go   }
		qr/go\(\) is an abstract method of IT::Vehicle/,
		'go() (attribute form) croaks on IT::Vehicle itself';
	throws_ok { IT::Vehicle->new->stop }
		qr/stop\(\) is an abstract method of IT::Vehicle/,
		'stop() (declarative form) croaks on IT::Vehicle itself';
};

# ===================================================================
# SECTION 6: Re-abstraction
# ===================================================================

# A concrete method provided at an intermediate level is accessible to
# all subclasses, including those that add their own abstract methods.
subtest 're-abstraction: concrete leaf satisfies all abstract methods at all levels' => sub {
	plan tests => 3;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	diag 'IT::Concrete extends IT::Middle extends IT::Base' if $ENV{TEST_VERBOSE};

	my $obj = new_ok 'IT::Concrete';
	lives_and { is(IT::Concrete->new->process,  $config{proc_result})    } 'process() (from Middle) works';
	lives_and { is(IT::Concrete->new->validate, $config{validate_result}) } 'validate() (from Concrete) works';
};

subtest 're-abstraction: middle-layer abstract method croaks if not implemented' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# PartialMiddle inherits process() (concrete from Middle) but has no validate()
	lives_ok  { IT::PartialMiddle->new->process }
		'process() is satisfied via IT::Middle (inherited concrete)';
	throws_ok { IT::PartialMiddle->new->validate }
		qr/validate\(\) is an abstract method of IT::Middle/,
		'validate() is still abstract in IT::PartialMiddle';
};

# ===================================================================
# SECTION 7: Independent packages with the same method name
# ===================================================================

# Each abstract method wrapper belongs to its declaring package.
# Implementing activate() in Plugin1Impl satisfies ONLY Plugin1::activate.
subtest 'independent packages: same method name enforced independently' => sub {
	plan tests => 4;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	diag 'Plugin1 and Plugin2 both have abstract activate() -- independent wrappers' if $ENV{TEST_VERBOSE};

	# Each implementing subclass satisfies only its own parent's abstract method
	lives_and { is(IT::Plugin1Impl->new->activate, $config{plugin1_result}) }
		'Plugin1Impl::activate works (satisfies Plugin1 contract)';
	lives_and { is(IT::Plugin2Impl->new->activate, $config{plugin2_result}) }
		'Plugin2Impl::activate works (satisfies Plugin2 contract)';

	# The bare base classes still enforce independently
	throws_ok { IT::Plugin1->new->activate }
		qr/activate\(\) is an abstract method of IT::Plugin1/,
		'IT::Plugin1::activate still croaks on base class itself';
	throws_ok { IT::Plugin2->new->activate }
		qr/activate\(\) is an abstract method of IT::Plugin2/,
		'IT::Plugin2::activate still croaks on base class itself';
};

# ===================================================================
# SECTION 8: Concurrent instances
# ===================================================================

# N identical objects must each enforce the abstract method independently.
# Enforcement is purely per-call, not per-instance, so this verifies
# that no instance-level state is being shared or corrupted.
subtest 'concurrency: N instances enforce independently' => sub {
	my $n = $config{n_instances};
	plan tests => $n * 2;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	diag "Creating $n IT::Dog + IT::Blob instances concurrently" if $ENV{TEST_VERBOSE};

	my @dogs  = map { IT::Dog->new  } 1 .. $n;
	my @blobs = map { IT::Blob->new } 1 .. $n;

	# All dog instances must succeed; all blob instances must croak
	for my $i (0 .. $n - 1) {
		lives_ok  { $dogs[$i]->speak }  "dog instance $i: speak (implemented) lives";
		throws_ok { $blobs[$i]->speak }
			qr/abstract method/,
			"blob instance $i: speak (not implemented) croaks";
	}
};

# Mix multiple different classes concurrently to verify no cross-contamination.
subtest 'concurrency: mixed classes enforce without cross-contamination' => sub {
	plan tests => 6;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	diag 'Concurrent Cat, Blob, Triangle, BrokenPolygon instances' if $ENV{TEST_VERBOSE};

	my @cats  = map { IT::Cat->new          } 1 .. 3;
	my @blobs = map { IT::Blob->new         } 1 .. 3;
	my @tris  = map { IT::Triangle->new     } 1 .. 3;
	my @broken = map { IT::BrokenPolygon->new } 1 .. 3;

	# Implemented methods must succeed regardless of failing objects nearby
	lives_ok { $cats[0]->speak } 'cat speaks (concurrent)';
	lives_ok { $cats[0]->eat   } 'cat eats (concurrent)';
	lives_ok { $tris[0]->area  } 'triangle area works (concurrent)';

	# Unimplemented calls must still croak even with live objects present
	throws_ok { $blobs[0]->speak   } qr/abstract method/, 'blob speak croaks (concurrent)';
	throws_ok { $blobs[1]->eat     } qr/abstract method/, 'blob eat croaks (concurrent)';
	throws_ok { $broken[0]->sides  } qr/abstract method/, 'BrokenPolygon::sides croaks (concurrent)';
};

# ===================================================================
# SECTION 9: Stateful objects
# ===================================================================

# Multiple counter instances must maintain completely independent state;
# resetting one must not affect any other.
subtest 'stateful: multiple instances maintain independent state' => sub {
	plan tests => 6;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	diag 'Testing independent state across IT::ResettableCounter instances' if $ENV{TEST_VERBOSE};

	my $a = new_ok 'IT::ResettableCounter';
	my $b = new_ok 'IT::ResettableCounter';

	# Both start at zero
	is $a->count, 0, 'counter a initial value is 0';
	is $b->count, 0, 'counter b initial value is 0';

	# Increment only a -- b must remain at zero
	$a->increment for 1 .. $config{counter_steps};
	is $a->count, $config{counter_steps}, 'counter a incremented to expected value';
	is $b->count, 0,                      'counter b unchanged after a is mutated';
};

subtest 'stateful: abstract reset() croaks when not implemented' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# Increment a broken counter so it has non-zero state
	my $broken = IT::BrokenCounter->new;
	$broken->increment for 1 .. 3;

	throws_ok { $broken->reset }
		qr/reset\(\) is an abstract method of IT::Counter/,
		'IT::BrokenCounter::reset croaks (not implemented)';

	# The count must be unchanged after the failed abstract method call
	is $broken->count, 3, 'count unchanged after blocked abstract reset() call';
};

subtest 'stateful: concrete reset() works correctly' => sub {
	plan tests => 3;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	my $rc = IT::ResettableCounter->new;
	$rc->increment for 1 .. $config{counter_steps};
	is $rc->count, $config{counter_steps}, "counter at $config{counter_steps} before reset";

	lives_ok { $rc->reset } 'reset() lives in implementing class';
	is $rc->count, 0, 'count is zero after reset';
};

# ===================================================================
# SECTION 10: Composition / dependency injection
# ===================================================================

# Abstract Formatter acts as an interface contract.  Printer depends on
# it via composition.  The contract is enforced at call time regardless
# of how the dependency is wired.
subtest 'composition: concrete formatter works via dependency injection' => sub {
	plan tests => 3;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	diag 'IT::Printer + IT::HtmlFormatter -- concrete formatter' if $ENV{TEST_VERBOSE};

	my $fmt     = new_ok 'IT::HtmlFormatter';
	my $printer = IT::Printer->new($fmt);

	my $result;
	lives_ok { $result = $printer->print_it('hello') }
		'Printer with a concrete HtmlFormatter lives';
	is $result, $config{html_result}, 'formatted output matches expected HTML';
};

subtest 'composition: abstract formatter croaks when format() is not implemented' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# Passing the abstract base Formatter: print_it() will trigger the wrapper
	my $broken_printer = IT::Printer->new(IT::Formatter->new);
	throws_ok { $broken_printer->print_it('hello') }
		qr/format\(\) is an abstract method of IT::Formatter/,
		'Printer croaks when injected formatter has not implemented format()';
};

# ===================================================================
# SECTION 11: Error message format -- all three documented components
# ===================================================================

subtest 'error format: invocant from a blessed object (ref($_[0]))' => sub {
	plan tests => 3;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	my $err;
	eval { IT::Named->new->action };
	$err = $@;

	diag "Error: $err" if $ENV{TEST_VERBOSE};

	# All three parts of the documented format must appear in the error
	like $err, qr/action\(\)/,                           'error contains method name with ()';
	like $err, qr/is an abstract method of IT::Named/,   'error contains owner package';
	like $err, qr/must be implemented by IT::Named/,     'error names the invocant (blessed class)';
};

subtest 'error format: invocant from a class method call (bare string)' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# Class method call: $_[0] is the string 'IT::Named', not a blessed ref
	my $err;
	eval { IT::Named->action };
	$err = $@;

	diag "Class method error: $err" if $ENV{TEST_VERBOSE};

	like $err, qr/is an abstract method of IT::Named/,  'error contains owner package';
	like $err, qr/must be implemented by IT::Named/,    'invocant is the bare class string';
};

# ===================================================================
# SECTION 12: can() returns the croak-stub (documented known limitation)
# ===================================================================

# POD: "Animal->can('speak') returns the wrapper (truthy) rather than undef."
# This is a documented known limitation, not a bug.
subtest 'can() known limitation: returns truthy wrapper on abstract base' => sub {
	plan tests => 3;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	diag 'Verifying can() returns the stub wrapper (documented known limitation)' if $ENV{TEST_VERBOSE};

	# The stash entry IS the wrapper coderef, so can() returns it
	my $stub = IT::Animal->can('speak');
	ok defined($stub),         'IT::Animal->can("speak") returns a defined value';
	is reftype($stub), 'CODE', 'the returned value is a CODE ref (the wrapper)';

	# Calling the stub from any context still enforces the abstract contract
	throws_ok { $stub->(IT::Blob->new) }
		qr/abstract method/,
		'calling the can() stub directly still enforces the abstract contract';
};

subtest 'can() on implementing subclass returns the concrete sub' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# Cat overrides speak, so MRO resolves can() to Cat::speak, not the wrapper
	my $catsub = IT::Cat->can('speak');
	ok defined($catsub), 'IT::Cat->can("speak") is defined';

	# The concrete sub must return the correct value without croaking
	lives_and { is($catsub->(IT::Cat->new), $config{cat_speak}) }
		'IT::Cat->can("speak") returns the concrete sub (not the wrapper)';
};

# ===================================================================
# SECTION 13: UNIVERSAL registration (no per-package 'use Sub::Abstract')
# ===================================================================

# Once Sub::Abstract is loaded by any package, UNIVERSAL::Abstract is
# registered globally.  :Abstract can then be used in any package.
subtest 'UNIVERSAL: :Abstract works without per-package use Sub::Abstract' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	diag 'IT::NoUse has no "use Sub::Abstract" -- relies on UNIVERSAL::Abstract' if $ENV{TEST_VERBOSE};

	# Implementing subclass must work
	lives_ok { IT::NoUseImpl->new->run }
		'implementing subclass works (UNIVERSAL::Abstract was available)';

	# Base class must still croak
	throws_ok { IT::NoUse->new->run }
		qr/run\(\) is an abstract method of IT::NoUse/,
		'base class without per-package use still enforces the abstract contract';
};

# ===================================================================
# SECTION 14: BYPASS and %config bypass mechanics
# ===================================================================

subtest 'BYPASS=1 suppresses enforcement globally, restores on scope exit' => sub {
	plan tests => 3;
	local $ENV{HARNESS_ACTIVE} = 0;

	# With BYPASS=1 all abstract method calls must silently return
	{ local $Sub::Abstract::BYPASS = 1;
	  lives_ok { IT::Blob->new->speak } 'Blob::speak lives under BYPASS=1';
	  lives_ok { IT::Blob->new->eat   } 'Blob::eat lives under BYPASS=1'; }

	# After the BYPASS scope exits enforcement must resume
	{ local $Sub::Abstract::BYPASS = 0;
	  throws_ok { IT::Blob->new->speak }
		  qr/abstract method/,
		  'enforcement resumes immediately after BYPASS scope exits'; }
};

subtest 'HARNESS_ACTIVE: bypass respects the harness_bypass config flag' => sub {
	plan tests => 2;
	local $Sub::Abstract::BYPASS = 0;

	# HARNESS_ACTIVE=1 with default harness_bypass=1 suppresses enforcement
	{ local $ENV{HARNESS_ACTIVE} = 1;
	  lives_ok { IT::Blob->new->speak }
		  'HARNESS_ACTIVE=1 suppresses enforcement (harness_bypass=1)'; }

	# harness_bypass=0 disables the HARNESS_ACTIVE bypass entirely
	{ local $ENV{HARNESS_ACTIVE}                   = 1;
	  local $Sub::Abstract::config{harness_bypass} = 0;
	  throws_ok { IT::Blob->new->speak }
		  qr/abstract method/,
		  'harness_bypass=0 re-enables enforcement even with HARNESS_ACTIVE=1'; }
};

# ===================================================================
# SECTION 15: Error recovery
# ===================================================================

# A croak must not corrupt any surrounding object state or prevent
# subsequent legitimate calls on the same or other objects.
subtest 'error recovery: objects remain usable after an abstract method croak' => sub {
	plan tests => 4;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	diag 'Verifying objects stay usable after a croak' if $ENV{TEST_VERBOSE};

	my $cat  = IT::Cat->new;
	my $blob = IT::Blob->new;

	# Trigger a croak via the blob
	my $first_err;
	eval { $blob->speak };
	$first_err = $@;
	ok $first_err, 'first abstract method call croaks as expected';

	# The cat object is unaffected; its concrete method still works
	my $result;
	lives_ok { $result = $cat->speak } 'IT::Cat still usable after blob croaked';
	is $result, $config{cat_speak},    'IT::Cat::speak returns correct value after recovery';

	# A second call on blob still croaks (the wrapper is still in place)
	my $second_err;
	eval { $blob->speak };
	$second_err = $@;
	ok $second_err, 'second abstract call also croaks (wrapper remains active)';
};

# ===================================================================
# SECTION 16: import() return value
# ===================================================================

subtest 'import(): return value is the class name in all call forms' => sub {
	plan tests => 4;

	# No-args form returns the class name
	my $r1 = Sub::Abstract->import();
	is $r1, $SA, 'import() no-args returns the class name';
	returns_ok($r1, { type => 'string' }, 'no-args return value satisfies string schema');

	# Declarative (post-CHECK) form also returns the class name
	{ package IT::ReturnCheck; sub _rc { 1 } }
	my $r2;
	{ package IT::ReturnCheck; $r2 = Sub::Abstract->import('_rc'); }
	is $r2, $SA, 'import() with sub name returns the class name';
	returns_ok($r2, { type => 'string' }, 'declarative return value satisfies string schema');
};

# ===================================================================
# SECTION 17: Spy verification via Test::Mockingbird
# ===================================================================

# Verify croak is called exactly once per abstract method violation.
subtest 'spy: croak called exactly once per abstract method call' => sub {
	plan tests => 3;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	my $spy = spy 'Sub::Abstract::croak';
	eval { IT::Blob->new->speak };

	my @calls = $spy->();
	diag 'croak spy calls: ' . scalar(@calls) if $ENV{TEST_VERBOSE};

	is scalar(@calls), 1, 'croak called exactly once per abstract method call';
	like $calls[0][1], qr/speak\(\) is an abstract method of IT::Animal/,
		'croak message contains the method name and owner package';
	like $calls[0][1], qr/must be implemented by IT::Blob/,
		'croak message names IT::Blob as the invocant';

	restore_all();
};

# Verify croak is NOT called when a concrete subclass satisfies the contract.
subtest 'spy: croak NOT called for a concrete subclass call' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	my $spy = spy 'Sub::Abstract::croak';
	my $result;
	lives_ok { $result = IT::Cat->new->speak } 'IT::Cat::speak lives';

	my @calls = $spy->();
	is scalar(@calls), 0, 'croak NOT called for a concrete subclass method call';

	restore_all();
};

# Verify that the croak count accumulates correctly across multiple
# violations interleaved with legitimate calls.
subtest 'spy: croak count matches number of violations across mixed calls' => sub {
	plan tests => 3;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	my $spy = spy 'Sub::Abstract::croak';

	# Two separate violations
	eval { IT::Blob->new->speak };
	eval { IT::Blob->new->eat   };
	my @after_two = $spy->();
	is scalar(@after_two), 2, 'croak count is 2 after two violations';

	# Sandwiched concrete calls must NOT inflate the count
	IT::Cat->new->speak;
	IT::Cat->new->eat;
	my @after_concrete = $spy->();
	is scalar(@after_concrete), 2,
		'croak count unchanged after two concrete calls';

	# A third violation increments the count to three
	eval { IT::Animal->new->speak };
	my @after_three = $spy->();
	is scalar(@after_three), 3, 'croak count is 3 after a third violation';

	restore_all();
};

# Verify validate_strict is called once per sub name during import().
subtest 'spy: validate_strict called per sub name during import()' => sub {
	plan tests => 2;

	diag 'Spying on validate_strict during declarative import()' if $ENV{TEST_VERBOSE};

	my $spy = spy 'Sub::Abstract::validate_strict';

	{ package IT::SpyImport;
	  sub _a { 1 }
	  sub _b { 2 }
	  Sub::Abstract->import('_a', '_b'); }

	my @calls = $spy->();
	ok scalar(@calls) >= 2,
		'validate_strict called at least once per sub name (2 names -> >= 2 calls)';

	# Each call must carry the documented "schema" key
	ok(
		(grep { defined $_ && $_ eq 'schema' } @{$calls[0]}),
		'validate_strict called with the "schema" key as documented'
	);

	restore_all();
};

# ===================================================================
# SECTION 18: Moo integration (skip if Moo not available)
# ===================================================================

# Sub::Abstract is documented as "for plain-Perl OO only", but since
# UNIVERSAL::Abstract is globally installed, it is technically compatible
# with Moo classes.  This test verifies there is no interference.
subtest 'Moo integration: :Abstract enforces in Moo-based class' => sub {
	test_needs 'Moo';

	{
		package IT::MooBase;
		use Moo;
		use Sub::Abstract;
		sub render :Abstract { }    # abstract method inside a Moo class
	}

	{
		package IT::MooImpl;
		use Moo;
		our @ISA = ('IT::MooBase');
		sub render { 'moo rendered' }
	}

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	diag 'Testing Sub::Abstract + Moo class interaction' if $ENV{TEST_VERBOSE};

	# Implementing Moo subclass must succeed
	my $obj = IT::MooImpl->new;
	my $result;
	lives_ok { $result = $obj->render }
		'Moo: implementing subclass can call render()';
	is $result, 'moo rendered', 'Moo: correct return value from concrete render()';

	# Moo base without implementation must croak
	throws_ok { IT::MooBase->new->render }
		qr/render\(\) is an abstract method of IT::MooBase/,
		'Moo: abstract method still croaks on the base class';
};

# ===================================================================
# SECTION 19: SUPER:: dispatch to an abstract method
#
# When a subclass method explicitly calls $self->SUPER::abstract_method,
# the abstract wrapper in the base class is reached directly.  The
# invocant inside the wrapper is still the subclass instance.
# ===================================================================

subtest 'SUPER:: dispatch: abstract wrapper fires when reached via SUPER::' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	diag 'IT::SuperCallSub::render calls $self->SUPER::render' if $ENV{TEST_VERBOSE};

	# The error must identify the method and the abstract base
	throws_ok { IT::SuperCallSub->new->render }
		qr/render\(\) is an abstract method of IT::SuperCallBase/,
		'SUPER:: dispatch: error names the method and the base package';

	# The invocant must be the subclass (the object that started the call)
	throws_ok { IT::SuperCallSub->new->render }
		qr/must be implemented by IT::SuperCallSub/,
		'SUPER:: dispatch: invocant in error is the concrete subclass';
};

# ===================================================================
# SECTION 20: can() stub is callable and croaks with the full message
#
# POD documents that can() returns the wrapper (truthy) rather than
# undef.  This section verifies not just truthiness but that calling
# the returned coderef produces the documented abstract-method croak.
# ===================================================================

subtest 'can() stub is callable and croaks when invoked directly' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# can() must return the wrapper, not undef -- documented limitation
	my $stub = IT::Animal->can('speak');
	ok $stub, 'can("speak") returns a truthy coderef (documented limitation)';

	# Calling the returned coderef with a non-implementing object must croak
	throws_ok { $stub->(IT::Blob->new) }
		qr/speak\(\) is an abstract method of IT::Animal/,
		'can() coderef: calling it directly triggers the abstract croak';
};

done_testing;
