#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Term::VTerm::Color;

my $color = Term::VTerm::Color->new( red => 10, green => 20, blue => 30 );

isa_ok( $color, "Term::VTerm::Color", '$color' );

is( $color->red,   10, '$color->red' );
is( $color->green, 20, '$color->green' );
is( $color->blue,  30, '$color->blue' );

is( $color->rgb_hex, "0a141e", '$color->rgb_hex' );

done_testing;
