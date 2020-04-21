#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Struct::Dumb;
BEGIN {
   plan skip_all => "No Data::Dump" unless eval { require Data::Dump; };

   Data::Dump->import( 'pp' );
}

struct Point => [qw( x y )];

{
   my $point = Point( 10, 20 );

   is( pp( $point ),
      'main::Point(10, 20)',
      'Data::Dump::pp can dump a Point when loaded after' );
}

done_testing;
