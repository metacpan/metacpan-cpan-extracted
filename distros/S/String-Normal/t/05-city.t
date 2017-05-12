#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

use String::Normal;
my $obj = String::Normal->new( type => 'city' );

is $obj->transform( 'New York' ), 'new york',           "correct transform";
is $obj->transform( 'Los Angeles' ),   'los angeles',   "correct transform";
