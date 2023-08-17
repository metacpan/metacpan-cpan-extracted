#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Object::Pad;
use Object::Pad::ClassAttr::Struct;

class Example :Struct(readonly) {
   field $x;
   field $y;
   field $z = undef;
}

{
   my $obj = Example->new( x => 10, y => 20, z => 30 );
   is( $obj->x, 10, 'Object still has readers' );

   ok( !defined eval { $obj->x = 40 },
      'Failed to set x of readonly struct' );
   is( $obj->x, 10, 'Object unchanged after failed attempt to mutate' );
}

done_testing;
