use strict;
use warnings;
use Test::More tests => 14;

# Cross-class function-style accessor tests
# Function accessors work by slot index, not class identity

BEGIN {
    require Object::Proto;
    Object::Proto::define('Animal', qw(name age));
    Object::Proto::define('Robot', qw(name age));
    Object::Proto::define('Vehicle', qw(make model year));
    Object::Proto::import_accessors('Animal');  # name(), age() in main::
}

use Object::Proto;

# Animal object - normal use
my $dog = new Animal 'Rex', 5;
is(name($dog), 'Rex', 'func accessor on own class getter');
age($dog, 6);
is(age($dog), 6, 'func accessor on own class setter');

# Robot has same slot layout - should work transparently
my $bot = new Robot 'C3PO', 100;
is(name($bot), 'C3PO', 'func accessor on different class with same slot layout');
is(age($bot), 100, 'func accessor getter works cross-class');

# Setter works cross-class too
age($bot, 200);
is(age($bot), 200, 'func accessor setter works cross-class');

# Original object unaffected
is(age($dog), 6, 'cross-class setter does not affect other objects');

# Vehicle has different slot names but same indices
my $car = new Vehicle 'Toyota', 'Camry', 2024;
# name() maps to slot 1 which is 'make' in Vehicle
is(name($car), 'Toyota', 'func accessor reads by slot index across different schemas');
# age() maps to slot 2 which is 'model' in Vehicle
is(age($car), 'Camry', 'func accessor reads slot 2 regardless of property name');

# Setter on mismatched schema still works by index
age($car, 'Corolla');
is(age($car), 'Corolla', 'func accessor setter works by slot index');

# import_accessor with alias works cross-class
BEGIN {
    Object::Proto::import_accessor('Animal', 'name', 'get_name');
}
is(get_name($dog), 'Rex', 'aliased accessor on own class');
is(get_name($bot), 'C3PO', 'aliased accessor on cross-class object');

# Method-style still works on all objects
is($dog->name, 'Rex', 'method-style still works on Animal');
is($bot->name, 'C3PO', 'method-style still works on Robot');
is($car->make, 'Toyota', 'method-style uses correct property name');
