#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Struct::Dumb;

struct Point => [qw( x y )], predicate => "is_Point";

my $point = Point(10, 20);
ok( is_Point( $point ), '$point is a Point' );

ok( !is_Point( [] ), 'unblessed ARRAYref is not a Point' );

done_testing;
