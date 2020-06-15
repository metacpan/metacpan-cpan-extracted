#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Object::Pad;

class Colour {
   has $red   :reader            :writer;
   has $green :reader(get_green) :writer;
   has $blue  :mutator;

   BUILD {
      ( $red, $green, $blue ) = @_;
   }

   method rgb {
      ( $red, $green, $blue );
   }
}

# readers
{
   my $col = Colour->new(50, 60, 70);

   is( $col->red,       50, '$col->red' );
   is( $col->get_green, 60, '$col->get_green' );
   is( $col->blue,      70, '$col->blue' );
}

# writers
{
   my $col = Colour->new;

   $col->set_red( 80 );
   $col->set_green( 90 );
   $col->blue = 100;

   is_deeply( [ $col->rgb ], [ 80, 90, 100 ],
      '$col->rgb after writers' );
}

done_testing;
