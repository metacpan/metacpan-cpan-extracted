#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Object::Pad 0.800;

class BaseClass {
   field $data = 123;
}

package ExtendedClass {
   use base qw( BaseClass );

   sub moremethod { return 456 }
}

my $obj = ExtendedClass->new;
isa_ok( $obj, [ "ExtendedClass" ], '$obj' );

is( $obj->moremethod, 456, '$obj has methods from ExtendedClass' );

done_testing;
