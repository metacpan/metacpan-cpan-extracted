#!/usr/bin/env perl

#
# Testing private method.
# This method is not part of the public interface, and therefore may change at
# any time. It's functionality and existence are not guaranteed.
#

use Test::More;
use Carp;

use strict;
use warnings;
use SVG::Sparkline;

my @good_colors = (
    '#000', '#fff', '#FFF', '#000000', '#ffffff',
    'rgb(1,2,3)', 'rgb(10%,20%,30%)',
    'red', 'blue', 'green',
);
my @bad_colors = ( 
    1234, 'fw123', '$%^&^',
    '#1', '#12', '#1234', '#12345', '#man',
    'rgb()', 'rgb(000)', 'rgb(1,2)', 'rgb(red,green,blue)',
    'rgb(10,24,100%)', 'rgb(', 'rgb(10%,'
);

plan tests=> (@good_colors+@bad_colors);

foreach my $color ( @good_colors )
{
    ok( SVG::Sparkline::_is_color( $color ), "Valid color: $color" );
}

foreach my $color ( @bad_colors )
{
    ok( !SVG::Sparkline::_is_color( $color ), "Invalid color: $color" );
}

