#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Struct::Dumb;

struct Colour => [qw( red green blue )], named_constructor => 1;

{
   my $colour = Colour( red => 1, green => 0, blue => 0 );

   can_ok( $colour, "red" );
   is( $colour->red, 1, '$colour->red is 1' );
}

{
   my $colour = Colour( green => 1, blue => 0.5, red => 0 );

   is( $colour->blue, 0.5, '$colour->blue is 0.5' );
}

{
   package named::default;
   use Struct::Dumb qw( -named_constructors );

   struct Point3D => [qw( x y z )];

   my $point = Point3D( x => 1, z => 3, y => 2 );
   ::is( $point->z, 3, '$point->z from default named constructor' );
}

like( exception { Colour( red => 0, green => 0 ) },
      qr/^usage: main::Colour requires 'blue' at \S+ line \d+\.?\n/,
      'Colour() without blue throws usage exception' );

like( exception { Colour( red => 0, green => 0, blue => 0, yellow => 1 ) },
      qr/^usage: main::Colour does not recognise 'yellow' at \S+ line \d+\.?\n/,
      'Colour() with yellow throws usage exception' );

done_testing;
