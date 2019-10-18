#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Object::Pad;

class Point {
   has $x;
   has $y;

   method CREATE {
      ( $x, $y ) = @_;
   }

   method where { sprintf "(%d,%d)", $x, $y }
}

{
   my $p = Point->new( 10, 20 );
   is( $p->where, "(10,20)", '$p->where' );
}

done_testing;
