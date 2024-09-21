#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Object::Pad 0.800;

class Point {
   field $x :param;
   field $y :param = 0;

   method pos { return ( $x, $y ); }
}

{
   my $point = Point->new( x => 10 );
   is( [ $point->pos ], [ 10, 0 ],
      'Point with default y' );
}

{
   my $point = Point->new( x => 30, y => 40 );
   is( [ $point->pos ], [ 30, 40 ],
      'Point fully specified' );
}

class Point3D {
   inherit Point;

   field $z :param = 0;

   method pos { return ( $self->next::method, $z ) }
}

{
   my $point = Point3D->new( x => 50, y => 60, z => 70 );
   is( [ $point->pos ], [ 50, 60, 70 ],
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
      field $red   :param = 0;
      field $green :param = 0;
      field $blue  :param = 0;
   }

   my $LINE = __LINE__+1;
   ok( !defined eval { Colour->new( yellow => 1 ); 1 },
      'constructor complains about unrecognised param name' );
   like( $@, qr/^Unrecognised parameters for Colour constructor: 'yellow' at \S+ line $LINE\./,
      'exception message from unrecognised parameter' );
}

# Param assignment modes
{
   class AllTheOps {
      field $exists  :param   = "default";
      field $defined :param //= "default";
      field $true    :param ||= "default";

      method values { return ( $exists, $defined, $true ); }
   }

   is( [ AllTheOps->new(exists => "value", defined => "value", true => "value")->values ],
      [ "value", "value", "value" ],
      'AllTheOps for true values' );

   is( [ AllTheOps->new(exists => 0, defined => 0, true => 0)->values ],
      [ 0, 0, "default" ],
      'AllTheOps for false values' );

   is( [ AllTheOps->new(exists => undef, defined => undef, true => undef)->values ],
      [ undef, "default", "default" ],
      'AllTheOps for undef values' );

   is( [ AllTheOps->new()->values ],
      [ "default", "default", "default" ],
      'AllTheOps for missing values' );
}

done_testing;
