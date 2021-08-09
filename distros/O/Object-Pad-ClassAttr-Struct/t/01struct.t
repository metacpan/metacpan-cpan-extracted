#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;
use Object::Pad::ClassAttr::Struct;

class Example :Struct {
   has $x;
   has $y;
   has $z = undef;
}

{
   my $obj = Example->new( x => "the x", y => "the y" );
   is( $obj->x, "the x", 'obj has ->x from constructor' );
   is( $obj->y, "the y", 'obj has ->y from constructor' );

   $obj->z = "the z";
   is( $obj->z, "the z", 'obj has ->z from mutator' );
}

done_testing;
