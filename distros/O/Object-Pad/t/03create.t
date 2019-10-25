#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Object::Pad;

class Point {
   has $x = 0;
   has $y = 0;

   method BUILDALL {
      ( $x, $y ) = @_;
   }

   method where { sprintf "(%d,%d)", $x, $y }
}

{
   my $p = Point->new( 10, 20 );
   is( $p->where, "(10,20)", '$p->where' );
}

done_testing;
