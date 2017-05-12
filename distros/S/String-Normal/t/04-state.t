#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

use String::Normal;
my $obj = String::Normal->new( type => 'state' );

is $obj->transform( 'California' ), 'ca',   "correct transform";
is $obj->transform( 'CA' ),   'ca',   "correct transform";
