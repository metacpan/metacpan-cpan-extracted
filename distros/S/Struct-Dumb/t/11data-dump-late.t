#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Struct::Dumb;
use Data::Dump 'pp';

struct Point => [qw( x y )];

{
   my $point = Point( 10, 20 );

   is( pp( $point ),
      'main::Point(10, 20)',
      'Data::Dump::pp can dump a Point when loaded after' );
}

done_testing;
