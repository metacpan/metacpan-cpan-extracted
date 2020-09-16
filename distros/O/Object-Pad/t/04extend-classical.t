#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;

class BaseClass {
   has $data = 123;
}

package ExtendedClass {
   use base qw( BaseClass );

   sub moremethod { return 456 }
}

my $obj = ExtendedClass->new;
isa_ok( $obj, "ExtendedClass", '$obj' );

is( $obj->moremethod, 456, '$obj has methods from ExtendedClass' );

done_testing;
