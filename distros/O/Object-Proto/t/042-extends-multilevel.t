#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Object::Proto;

# === Multi-level inheritance: Grandparent -> Parent -> Child ===

Object::Proto::define('Creature',
    'alive:Int:default(1)',
);

Object::Proto::define('Mammal',
    extends => 'Creature',
    'warm_blooded:Int:default(1)',
    'legs:Int:default(4)',
);

Object::Proto::define('Cat',
    extends => 'Mammal',
    'name:Str:required',
    'indoor:Int:default(1)',
);

# Cat should have all properties from the chain
my @props = sort(Object::Proto::properties('Cat'));
is_deeply(\@props, [qw(alive indoor legs name warm_blooded)], 'multi-level: all properties present');

# Create instance
my $cat = new Cat name => 'Whiskers';
is($cat->name, 'Whiskers', 'own property');
is($cat->legs, 4, 'parent default');
is($cat->warm_blooded, 1, 'parent default');
is($cat->alive, 1, 'grandparent default');
is($cat->indoor, 1, 'own default');

# isa chain
ok($cat->isa('Cat'), 'isa Cat');
ok($cat->isa('Mammal'), 'isa Mammal');
ok($cat->isa('Creature'), 'isa Creature');

# ancestors
my @ancestors = Object::Proto::ancestors('Cat');
is_deeply(\@ancestors, ['Mammal', 'Creature'], 'ancestors returns full chain');

# parent
is(Object::Proto::parent('Cat'), 'Mammal', 'parent of Cat is Mammal');
is(Object::Proto::parent('Mammal'), 'Creature', 'parent of Mammal is Creature');
ok(!defined Object::Proto::parent('Creature'), 'Creature has no parent');

done_testing;
