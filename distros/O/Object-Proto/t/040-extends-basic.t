#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Object::Proto;

# === Basic single-level extends ===

Object::Proto::define('Animal',
    'name:Str:required',
    'species:Str:default(unknown)',
);

package Animal;
sub speak { my $self = shift; return $self->name . " says hello" }
package main;

Object::Proto::define('Dog',
    extends => 'Animal',
    'breed:Str',
    'tricks:Int:default(0)',
);

# Dog should have parent properties + own
my @dog_props = sort(Object::Proto::properties('Dog'));
is_deeply(\@dog_props, [qw(breed name species tricks)], 'Dog has all properties (parent + own)');

# Create dog with all properties
my $dog = new Dog name => 'Rex', species => 'canine', breed => 'Labrador', tricks => 5;
is($dog->name, 'Rex', 'inherited property getter works');
is($dog->species, 'canine', 'inherited property with default works when set');
is($dog->breed, 'Labrador', 'own property getter works');
is($dog->tricks, 5, 'own typed property works');

# Inherited default
my $dog2 = new Dog name => 'Buddy', breed => 'Poodle';
is($dog2->species, 'unknown', 'inherited default value works');
is($dog2->tricks, 0, 'own default value works');

# Setters work
$dog->breed('Golden');
is($dog->breed, 'Golden', 'own property setter works');
$dog->name('Max');
is($dog->name, 'Max', 'inherited property setter works');

# isa works via @ISA
ok($dog->isa('Dog'), 'isa Dog');
ok($dog->isa('Animal'), 'isa Animal (parent)');

# Inherited methods via @ISA
is($dog->speak, 'Max says hello', 'inherited method works via @ISA');

# can works
ok($dog->can('speak'), 'can(speak) from parent');
ok($dog->can('breed'), 'can(breed) own accessor');
ok($dog->can('name'), 'can(name) inherited accessor');

# === Introspection ===
is(Object::Proto::parent('Dog'), 'Animal', 'parent() returns Animal');
ok(!defined Object::Proto::parent('Animal'), 'parent() of root is undef');

my @ancestors = Object::Proto::ancestors('Dog');
is_deeply(\@ancestors, ['Animal'], 'ancestors() returns [Animal]');

my @animal_ancestors = Object::Proto::ancestors('Animal');
is_deeply(\@animal_ancestors, [], 'ancestors() of root is empty');

done_testing;
