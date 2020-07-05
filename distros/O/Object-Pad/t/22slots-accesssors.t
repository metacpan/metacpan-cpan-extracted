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

   # Reader complains if given any arguments
   my $LINE = __LINE__+1;
   ok( !defined eval { $col->red(55); 1 },
      'reader method complains if given any arguments' );
   like( $@, qr/^Too many arguments for subroutine(?: \S+)?(?: at \S+ line $LINE\.)?$/,
      'exception message from too many arguments to reader' );
}

# writers
{
   my $col = Colour->new;

   $col->set_red( 80 );
   is( $col->set_green( 90 ), $col, '->set_* writer returns invocant' );
   $col->blue = 100;

   is_deeply( [ $col->rgb ], [ 80, 90, 100 ],
      '$col->rgb after writers' );

   # Writer complains if not given enough arguments
   my $LINE = __LINE__+1;
   ok( !defined eval { $col->set_red; 1 },
      'writer method complains if given no argument' );
   like( $@, qr/^Too few arguments for subroutine(?: \S+)?(?: at \S+ line $LINE\.)?$/,
      'exception message from too few arguments to writer' );
}

done_testing;
