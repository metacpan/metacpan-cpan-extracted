#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Struct::Dumb;

struct Point => [qw( x y )], predicate => "is_Point";

my $point = Point(10, 20);
ok( is_Point( $point ), '$point is a Point' );

ok( !is_Point( [] ), 'unblessed ARRAYref is not a Point' );

done_testing;
