#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;
use Object::Pad::SlotAttr::Isa;

class Point {
   has $x :param :reader;
   has $y :param :reader;
}

class Rectangle {
   has $start :Isa(Point) :param :reader :writer;
   has $end   :Isa(Point) :param :reader :writer;
}

{
   my $origin = Point->new( x => 0, y => 0 );
   my $oneone = Point->new( x => 1, y => 1 );

   my $rect = Rectangle->new( start => $origin, end => $oneone );
   ok( defined $rect, 'Rectangle->new with Points OK' );

   ok( !defined eval { $rect->set_start( "(2,2)" ); 1 },
      'Mutator with wrong type fails' );
   like( $@, qr/^Slot \$start requires an object of type Point at /,
      'Failure message from mutator attempt' );

   is( $rect->start->x, 0, 'Object remains unaffected by failed mutator attempt' );
}

{
   ok( !defined eval { Rectangle->new( start => "origin", end => "oneone" ) },
      'Construction with wrong types fails' );
   like( $@, qr/^Slot \$start requires an object of type Point at /,
      'Failure message from construction attempt' );
}

done_testing;
