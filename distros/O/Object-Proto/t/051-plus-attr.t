#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 24;

use Object::Proto;

# Base class with various attributes
Object::Proto::define('Animal',
    'name:Str:required',
    'age:Int:default(0)',
    'sound:Str:default(silent)',
    'is_wild:Bool:default(0)');

# Child class using +attr to modify inherited attributes
Object::Proto::define('Dog',
    extends => 'Animal',
    '+age:default(1)',           # Just change default
    '+sound:default(bark)',      # Just change default
    'breed:Str');                 # Add new attribute

# Test 1-4: Dog inherits types from Animal, uses new defaults
my $dog = Dog->new(name => 'Rex', breed => 'German Shepherd');
is($dog->name, 'Rex', 'name still required from parent');
is($dog->age, 1, '+age default changed to 1');
is($dog->sound, 'bark', '+sound default changed to bark');
is($dog->breed, 'German Shepherd', 'new attribute works');

# Test 5-6: Type constraint inherited
eval { Dog->new(name => 'Rex', breed => 'Lab', age => 'old') };
like($@, qr/expected Int/i, '+age still has Int type from parent');

eval { Dog->new(name => [], breed => 'Lab') };
like($@, qr/expected Str/i, 'name still enforces Str type');

# Test 7: required is still enforced
eval { Dog->new(breed => 'Lab') };
like($@, qr/required/i, 'name still required after inheritance');

# Child with +attr adding trigger
my $trigger_count = 0;

package Cat;
sub _on_sound_change { $trigger_count++ }
package main;

Object::Proto::define('Cat',
    extends => 'Animal',
    '+sound:default(meow):trigger(_on_sound_change)',
    '+is_wild:default(0)');

# Test 8-9: Cat gets new default and trigger
my $cat = Cat->new(name => 'Whiskers');
is($cat->sound, 'meow', 'Cat sound defaults to meow');
$cat->sound('purr');
is($trigger_count, 1, 'trigger from +attr fires');

# Test error case: +attr on non-existent attribute
eval {
    Object::Proto::define('BadChild',
        extends => 'Animal',
        '+nonexistent:default(oops)');
};
like($@, qr/no inherited attribute/, '+attr on missing attribute dies');

# Test 10: Multiple inheritance levels
Object::Proto::define('Puppy',
    extends => 'Dog',
    '+age:default(0)',  # Override Dog's override
    '+breed:default(Mixed)');

my $puppy = Puppy->new(name => 'Spot');
is($puppy->age, 0, 'Puppy +age overrides Dog default');
is($puppy->breed, 'Mixed', 'Puppy +breed gets default');
is($puppy->sound, 'bark', 'Puppy inherits sound from Dog');

# Test 11-12: Full override still works alongside +attr
Object::Proto::define('Wolf',
    extends => 'Animal',
    '+sound:default(howl)',
    'is_wild:Bool:default(1)');  # Full override (no +)

my $wolf = Wolf->new(name => 'Grey');
is($wolf->sound, 'howl', '+attr works');
is($wolf->is_wild, 1, 'full override works alongside +attr');

# Test 13-14: +attr with builder
Object::Proto::define('Bird',
    extends => 'Animal',
    '+name:builder(_build_name)');

sub Bird::_build_name { 'Tweety' }

my $bird = Bird->new();  # name no longer required since has builder
is($bird->name, 'Tweety', '+attr with builder merges onto type');

# Verify type still enforced
eval { $bird->name({}) };
like($@, qr/expected Str/i, 'type preserved after +builder');

# Test 15-16: +attr with is:ro
Object::Proto::define('ReadOnlyAnimal',
    extends => 'Animal',
    '+age:readonly');

my $ro_animal = ReadOnlyAnimal->new(name => 'Immutable', age => 5);
is($ro_animal->age, 5, 'readonly animal age set');
eval { $ro_animal->age(10) };
like($@, qr/readonly/i, '+attr can add readonly');

# Test 17-18: +attr preserving clearer/predicate
Object::Proto::define('Item',
    'value:Int:default(0):clearer:predicate');

Object::Proto::define('SpecialItem',
    extends => 'Item',
    '+value:default(100)');

my $item = SpecialItem->new();
is($item->value, 100, 'SpecialItem has new default');
ok($item->has_value, 'predicate preserved');
$item->clear_value;
ok(!$item->has_value, 'clearer preserved');

# Test 19: +attr only changes what's specified
Object::Proto::define('Config',
    'timeout:Int:default(30):required',
    'retries:Int:default(3)');

Object::Proto::define('FastConfig',
    extends => 'Config',
    '+timeout:default(5)');  # Change default, keep required

my $fc = FastConfig->new(timeout => 10);
is($fc->timeout, 10, 'can still override default');
is($fc->retries, 3, 'untouched attr keeps original default');

done_testing;
