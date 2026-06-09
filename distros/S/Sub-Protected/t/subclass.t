use strict;
use warnings;
use Test::Most;
use Sub::Protected;

# Tests 3-4, 14-15: subclass access, SUPER::, deep inheritance, prefix-only packages.

local $ENV{HARNESS_ACTIVE}    = 0;
local $Sub::Protected::BYPASS = 0;

# --- Packages for tests 3, 4, 14 ---

{
    package Animal;
    use Sub::Protected;
    sub new     { bless {}, shift }
    sub _breathe :Protected { 'animal breathe' }
    sub live    { (shift)->_breathe }
}

{
    package Dog;
    our @ISA = ('Animal');
    sub new   { bless {}, shift }
    # Test 3: direct subclass calling inherited protected sub
    sub bark  { Animal::_breathe(shift) }
}

{
    package Cat;
    our @ISA = ('Animal');
    sub new { bless {}, shift }
    # Test 4: override protected sub and call SUPER::
    sub _breathe :Protected {
        my $self = shift;
        'cat: ' . $self->SUPER::_breathe()
    }
    sub live { (shift)->_breathe }
}

{
    package Kitten;
    our @ISA = ('Cat');
    sub new  { bless {}, shift }
    # Test 14: two-hop subclass — Kitten isa Cat isa Animal
    sub play { Animal::_breathe(shift) }
}

# --- Packages for test 15 ---

{
    package AnimalWrong;   # same prefix "Animal" but NOT a subclass
    sub new  { bless {}, shift }
    sub probe { Animal->new->_breathe }
}

# Test 3: direct subclass can call inherited protected sub
my ($r3, $r4, $r14);
lives_ok { $r3 = Dog->new->bark }   'direct subclass call lives';
is $r3, 'animal breathe',           'direct subclass can call inherited protected sub';

# Test 4: SUPER:: call from overriding sub is allowed
lives_ok { $r4 = Cat->new->live }   'SUPER:: call lives';
is $r4, 'cat: animal breathe',      'SUPER:: call from overriding protected sub is allowed';

# Test 14: two-hop subclass is allowed (Kitten->isa('Animal') via Cat)
lives_ok { $r14 = Kitten->new->play } 'two-hop subclass call lives';
is $r14, 'animal breathe',            'two-hop subclass (C isa B isa A) can call A protected sub';

# Test 15: package with same prefix but no inheritance is blocked
throws_ok { AnimalWrong::probe() }
    qr/\Q_breathe() is a protected method of Animal and cannot be called from AnimalWrong\E/,
    'package with same name prefix but no isa relation is blocked';

done_testing;
