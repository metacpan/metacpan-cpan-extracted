#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Struct::Dumb qw( readonly_struct );

readonly_struct Point => [qw( x y )];

my $point = Point(10, 20);

is( $point->x, 10, '$point->x is 10' );

ok( exception { $point->y = 30 },
    '$point->y throws exception on readonly_struct' );

done_testing;
