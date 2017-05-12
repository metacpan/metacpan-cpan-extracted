#!/usr/bin/perl -T
use strict;
use Test::More;
use Net::P0f;

plan tests => 4;

my $interface = undef;

# calling as a class method
$interface = Net::P0f->lookupdev;
ok( defined $interface ); #01
ok( length $interface  ); #02

# calling as an object method
my $obj = new Net::P0f interface => $interface;
$interface = undef;
$interface = $obj->lookupdev;
ok( defined $interface ); #03
ok( length $interface  ); #04
