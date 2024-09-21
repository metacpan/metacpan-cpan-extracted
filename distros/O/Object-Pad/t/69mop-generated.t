#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Object::Pad::MOP::Class ':experimental(mop)';

# An attempt to programmatically generate everything
{
   my $classmeta = Object::Pad::MOP::Class->create_class( "Point" );

   my $xfieldmeta = $classmeta->add_field( '$x', reader => 'x' );
   my $yfieldmeta = $classmeta->add_field( '$y', reader => 'y' );

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

   $classmeta->seal;
}

{
   my $point = Point->new( 10, 20 );
   is( $point->describe, "Point(10, 20)",
      '$point->describe' );
   is( $point->x, 10, '$point->x' );
}

done_testing;
