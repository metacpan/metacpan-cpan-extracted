#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

# Test import_accessors with prefix (alias) argument
# Signature: Object::Proto::import_accessors($class, $prefix, $target)

# ============================================
# Basic prefix usage
# ============================================

BEGIN {
    require Object::Proto;

    Object::Proto::define('Animal', qw(name speed legs));
    Object::Proto::define('Vehicle', qw(name speed wheels));

    # Import Animal accessors with "animal_" prefix to avoid clashes
    Object::Proto::import_accessors('Animal', 'animal_');

    # Import Vehicle accessors with "vehicle_" prefix
    Object::Proto::import_accessors('Vehicle', 'vehicle_');
}

use Object::Proto;

# Test prefixed Animal accessors
{
    my $cat = new Animal name => 'Cat', speed => 30, legs => 4;

    is(animal_name($cat), 'Cat', 'prefixed getter: animal_name');
    is(animal_speed($cat), 30, 'prefixed getter: animal_speed');
    is(animal_legs($cat), 4, 'prefixed getter: animal_legs');

    animal_speed($cat, 50);
    is(animal_speed($cat), 50, 'prefixed setter: animal_speed');

    animal_name($cat, 'Cheetah');
    is(animal_name($cat), 'Cheetah', 'prefixed setter: animal_name');
}

# Test prefixed Vehicle accessors
{
    my $car = new Vehicle name => 'Tesla', speed => 200, wheels => 4;

    is(vehicle_name($car), 'Tesla', 'prefixed getter: vehicle_name');
    is(vehicle_speed($car), 200, 'prefixed getter: vehicle_speed');
    is(vehicle_wheels($car), 4, 'prefixed getter: vehicle_wheels');

    vehicle_speed($car, 250);
    is(vehicle_speed($car), 250, 'prefixed setter: vehicle_speed');
}

# ============================================
# No prefix (undef) behaves like before
# ============================================

BEGIN {
    Object::Proto::define('Color', qw(red green blue));
    Object::Proto::import_accessors('Color', undef);
}

{
    my $c = new Color red => 255, green => 128, blue => 0;
    is(red($c), 255, 'undef prefix: accessor works unprefixed');
    is(green($c), 128, 'undef prefix: green');
    is(blue($c), 0, 'undef prefix: blue');
}

# ============================================
# Empty string prefix behaves like no prefix
# ============================================

BEGIN {
    Object::Proto::define('Point', qw(px py));
    Object::Proto::import_accessors('Point', '');
}

{
    my $p = new Point px => 10, py => 20;
    is(px($p), 10, 'empty prefix: px accessor');
    is(py($p), 20, 'empty prefix: py accessor');
}

# ============================================
# Prefix with target package
# ============================================

BEGIN {
    Object::Proto::define('Sensor', qw(temp humidity));
    Object::Proto::import_accessors('Sensor', 'sensor_', 'SensorPkg');
}

{
    my $s = new Sensor temp => 22.5, humidity => 65;

    # Call via fully qualified name since they were imported into SensorPkg
    is(SensorPkg::sensor_temp($s), 22.5, 'prefix + target pkg: sensor_temp');
    is(SensorPkg::sensor_humidity($s), 65, 'prefix + target pkg: sensor_humidity');

    SensorPkg::sensor_temp($s, 25.0);
    is(SensorPkg::sensor_temp($s), 25.0, 'prefix + target pkg: setter works');
}

# ============================================
# Prefix avoids name collisions
# ============================================

BEGIN {
    Object::Proto::define('Dog', qw(name breed));
    Object::Proto::define('Cat2', qw(name color));
    Object::Proto::import_accessors('Dog', 'dog_', 'PetShop');
    Object::Proto::import_accessors('Cat2', 'cat_', 'PetShop');
}

{
    my $dog = new Dog name => 'Rex', breed => 'Lab';
    my $cat = new Cat2 name => 'Whiskers', color => 'orange';

    is(PetShop::dog_name($dog), 'Rex', 'collision avoidance: dog_name');
    is(PetShop::dog_breed($dog), 'Lab', 'collision avoidance: dog_breed');
    is(PetShop::cat_name($cat), 'Whiskers', 'collision avoidance: cat_name');
    is(PetShop::cat_color($cat), 'orange', 'collision avoidance: cat_color');
}

# ============================================
# Prefix with method-style still works
# ============================================

{
    my $cat = new Animal name => 'Felix', speed => 20, legs => 4;

    # Method-style accessors are unaffected by prefix import
    is($cat->name, 'Felix', 'method-style unaffected by prefix import');
    is($cat->speed, 20, 'method-style speed still works');
}

done_testing();
