#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

package Foo;
use Struct::Dumb;
struct Point => [qw( x y )];

package Bar;
use Struct::Dumb;
struct Point => [qw( x y z )];

package main;

my $point2 = Foo::Point(10, 20);
my $point3 = Bar::Point(10, 20, 30);

ok( !$point2->can( "z" ), '$point2 cannot ->z' );
can_ok( $point3, "z" );

done_testing;
