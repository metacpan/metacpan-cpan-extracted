#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
   plan skip_all => "No Data::Dump" unless eval { require Data::Dump; };

   Data::Dump->import( 'pp' );
}
use Struct::Dumb;

struct Point => [qw( x y )];

{
   my $point = Point( 10, 20 );

   is( pp( $point ),
      'main::Point(10, 20)',
      'Data::Dump::pp can dump a Point' );
}

struct PointX => [qw( x y )], named_constructor => 1;

{
   is( pp( PointX( x => 30, y => 40 ) ),
      'main::PointX(x => 30, y => 40)',
      'Data::Dump::pp dumps named constructors with names' );
}

done_testing;
