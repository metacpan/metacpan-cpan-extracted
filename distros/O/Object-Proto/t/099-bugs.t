#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Object::Proto;

# Define a class
Object::Proto::define('Cat', "name:default(Barry)", "age:default(100)");

# Test named constructor where key does not exist
my $cat1 = new Cat thing => 3;

is($cat1->name, 'Barry');
is($cat1->age, 100);

done_testing;
