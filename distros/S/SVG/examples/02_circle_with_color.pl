#!/usr/bin/perl

use strict;
use warnings;


use SVG;

# create an SVG object with a size of 200x200 pixels
my $svg = SVG->new(
    width  => 40,
    height => 40,
);

# add a circle with style
#  fill is the color used tof fill the circle
#  stroke is the color of the line used to draw the circle
#     these both can be either a name of a color or an RGB triplet
#  stroke-width is a non-negative integer, thw width of thr drawing line
#  stroke-opacity and fill-opacity are floating point numbers between 0 and 1.
#     1 means the line is totally opaque
#     0 means the line is totally transparent
$svg->circle(
    cx => 20,
    cy => 20,
    r  => 15,
    style => {
        'fill'           => 'rgb(255, 0, 0)',
        'stroke'         => 'blue',
        'stroke-width'   =>  5,
        'stroke-opacity' => 0.5,
        'fill-opacity'   => 0.5,
    },
);


# now render the SVG object, implicitly use svg namespace
print $svg->xmlify, "\n";

