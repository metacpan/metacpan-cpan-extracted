#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Object::Proto;

# Define a class
Object::Proto::define('Cat', qw(name age));

# Test positional constructor
my $cat1 = new Cat 'Whiskers', 3;
isa_ok($cat1, 'Cat', 'positional constructor creates Cat');
is($cat1->name, 'Whiskers', 'positional: name accessor works');
is($cat1->age, 3, 'positional: age accessor works');

# Test named pairs constructor
my $cat2 = new Cat name => 'Fluffy', age => 5;
isa_ok($cat2, 'Cat', 'named constructor creates Cat');
is($cat2->name, 'Fluffy', 'named: name accessor works');
is($cat2->age, 5, 'named: age accessor works');

# Test setter
$cat1->age(4);
is($cat1->age, 4, 'setter works');

# Test named pairs order independence
my $cat3 = new Cat age => 2, name => 'Mittens';
is($cat3->name, 'Mittens', 'named: order independent - name');
is($cat3->age, 2, 'named: order independent - age');

done_testing;
