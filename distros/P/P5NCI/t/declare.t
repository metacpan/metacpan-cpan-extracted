#! perl

use strict;
use warnings;

use Test::More tests => 1;

use P5NCI::Declare library => 'nci_test', path => 'src';

sub double_int :NCI( double_int => ii );

is( double_int( 10 ), 20, 'NCI attribute should install named thunk' );
