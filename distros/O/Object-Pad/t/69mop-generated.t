#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;

# An attempt to programmatically generate everything
BEGIN {
   package Point;
   my $classmeta = Object::Pad::MOP::Class->begin_class( "Point" );

   my $xfieldmeta = $classmeta->add_field( '$x' );
   my $yfieldmeta = $classmeta->add_field( '$y' );

   $classmeta->add_BUILD( sub {
      my $self = shift;
      my ( $x, $y ) = @_;
      $xfieldmeta->value($self) = $x;
      $yfieldmeta->value($self) = $y;
   } );

   $classmeta->add_method( describe => sub {
      my $self = shift;
      return sprintf "Point(%d, %d)",
         $xfieldmeta->value($self), $yfieldmeta->value($self);
   } );
}

{
   my $point = Point->new( 10, 20 );
   is( $point->describe, "Point(10, 20)",
      '$point->describe' );
}

done_testing;
