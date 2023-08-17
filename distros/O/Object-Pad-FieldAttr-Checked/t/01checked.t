#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Object::Pad;
use Object::Pad::FieldAttr::Checked;

package Numerical {
   sub check { return $_[1] =~ m/^\d+(?:\.\d+)?$/ }
}

class Point {
   field $x :Checked(Numerical) :param :reader :writer;
   field $y :Checked(Numerical) :param :reader :writer;
}

{
   my $p = Point->new( x => 0, y => 0 );
   ok( defined $p, 'Point->new with numbers OK' );

   $p->set_x( 20 );
   ok( $p->x, 20, '$p->x modified after successful ->set_x' );

   like( dies { $p->set_x( "hello" ) },
      qr/^Field \$x requires a value satisfying :Checked\(Numerical\) at /,
      '$p->set_x rejects invalid values' );
   ok( $p->x, 20, '$p->x unmodified after rejected ->set_x' );
}

done_testing;
