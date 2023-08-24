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

package ArrayRefChecker {
   sub check { return ref($_[1]) eq "ARRAY" }
}

class Data {
   sub ArrayRef
   {
      return bless {}, "ArrayRefChecker";
   }

   field $points :Checked(ArrayRef) :param :reader;
}

{
   my $d = Data->new( points => [ 1, 2, 3 ] );
   ok( defined $d, 'Data->new with arrayref OK' );

   like( dies { Data->new( points => "hello" ) },
      qr/^Field \$points requires a value satisfying :Checked\(ArrayRef\) at / );
}

class InternalsCanViolate {
   field $f :Checked(Numerical) :param;

   method test {
      $f = "a string value";
   }
}

{
   my $o = InternalsCanViolate->new( f => 1234 );
   ok( defined $o, 'InternalsCanViolate->new with valid param' );

   ok( lives { $o->test },
      'Object internally can violate its own :Checked constraint' ) or
      diag( "$@" );
}

done_testing;
