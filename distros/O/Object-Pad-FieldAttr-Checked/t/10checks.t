#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Object::Pad 0.800;
use Object::Pad::FieldAttr::Checked;

use Data::Checks 0.04 qw( Num Maybe );

class Point {
   field $x :Checked(Num) :param :reader :writer;
   field $y :Checked(Num) :param :reader :writer;
}

{
   my $p = Point->new( x => 0, y => 0 );
   ok( defined $p, 'Point->new with numbers OK' );

   $p->set_x( 20 );
   ok( $p->x, 20, '$p->x modified after successful ->set_x' );

   like( dies { $p->set_x( "hello" ) },
      qr/^Field \$x requires a value satisfying Num at /,
      '$p->set_x rejects invalid values' );
   ok( $p->x, 20, '$p->x unmodified after rejected ->set_x' );
}

class MaybePoint {
   field $x :Checked(Maybe Num) :param :reader :writer;
}

{
   my $p = MaybePoint->new( x => undef );
   ok( defined $p, 'MaybePoint->new permits undef for Maybe Num field' );

   like( dies { $p->set_x( "hello" ) },
      qr/^Field \$x requires a value satisfying Maybe\(Num\) at /,
      '$p->set_x rejects invalid values' );
}

done_testing;
