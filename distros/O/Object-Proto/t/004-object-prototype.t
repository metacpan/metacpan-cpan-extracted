#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Object::Proto;

Object::Proto::define('Animal', qw(name));
Object::Proto::define('Dog', qw(name breed));

# Create prototype
my $proto = new Animal 'Generic';

# Create object with prototype
my $dog = new Dog 'Rex', 'German Shepherd';
Object::Proto::set_prototype($dog, $proto);

# Test prototype access
my $p = Object::Proto::prototype($dog);
isa_ok($p, 'Animal', 'prototype returns Animal');
is($p->name, 'Generic', 'prototype name accessible');

# Test lock
Object::Proto::lock($dog);
ok(Object::Proto::is_locked($dog), 'is_locked returns true after lock');

# Test unlock
Object::Proto::unlock($dog);
ok(!Object::Proto::is_locked($dog), 'is_locked returns false after unlock');

# Test freeze
Object::Proto::freeze($dog);
ok(Object::Proto::is_frozen($dog), 'is_frozen returns true after freeze');
ok(Object::Proto::is_locked($dog), 'frozen object is also locked');

# Cannot unlock frozen
eval { Object::Proto::unlock($dog) };
like($@, qr/Cannot unlock frozen/, 'cannot unlock frozen object');

# Cannot modify frozen
eval { $dog->name('NewName') };
like($@, qr/Cannot modify frozen/, 'cannot modify frozen object');

done_testing;
