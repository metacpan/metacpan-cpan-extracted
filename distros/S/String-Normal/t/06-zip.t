#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More tests => 3;

use String::Normal;
my $obj = String::Normal->new( type => 'zip' );

is $obj->transform( '37130' ), 37130,       "correct transform";
is $obj->transform( '90292' ), 90292,       "correct transform";
is $obj->transform( 'K1A 0B1' ), 'k1a0b1',  "correct transform";
