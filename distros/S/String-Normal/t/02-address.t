#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

use String::Normal;
my $obj = String::Normal->new( type => 'address' );

is $obj->transform( '123 Baker Street' ),           '123 baker st',     "correct transform";
is $obj->transform( '123 Baker Avenue Ste Five' ),  '123 baker ave',    "correct transform";
