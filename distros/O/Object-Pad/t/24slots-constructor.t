#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;

class Point {
   has $x :param;
   has $y :param = 0;

   method pos { return ( $x, $y ); }
}

{
   my $point = Point->new( x => 10 );
   is_deeply( [ $point->pos ], [ 10, 0 ],
      'Point with default y' );
}

{
   my $point = Point->new( x => 30, y => 40 );
   is_deeply( [ $point->pos ], [ 30, 40 ],
      'Point fully specified' );
}

class Point3D isa Point {
   has $z :param = 0;

   method pos { return ( $self->next::method, $z ) }
}

{
   my $point = Point3D->new( x => 50, y => 60, z => 70 );
   is_deeply( [ $point->pos ], [ 50, 60, 70 ],
      'Point3D inherits params' );
}

# Required params checking
{
   my $LINE = __LINE__+1;
   ok( !defined eval { Point->new(); 1 },
      'constructor complains about missing required params' );
   like( $@, qr/^Required parameter 'x' is missing for Point constructor at \S+ line $LINE\./,
      'exception message from missing parameter' );
}

# Strict params checking
{
   class Colour :strict(params) {
      has $red   :param = 0;
      has $green :param = 0;
      has $blue  :param = 0;
   }

   my $LINE = __LINE__+1;
   ok( !defined eval { Colour->new( yellow => 1 ); 1 },
      'constructor complains about unrecognised param name' );
   like( $@, qr/^Unrecognised parameters for Colour constructor: yellow at \S+ line $LINE\./,
      'exception message from unrecognised parameter' );
}

done_testing;
