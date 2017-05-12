#!/usr/bin/perl

use strict;
use warnings;


use SVG;

# create an SVG object with a size of 200x200 pixels
my $svg = SVG->new(
    width  => 200,
    height => 200,
);
$svg->title()->cdata('I am a title');

# use explicit element constructor to generate a group element
my $y = $svg->group(
    id    => 'group_y',
    style => {
        stroke => 'red',
        fill   =>'green',
    },
);

# add a circle to the group
$y->circle(
    cx => 100,
    cy => 100,
    r  => 50,
    id => 'circle_in_group_y',
);

$y->comment('This is a comment');

# now render the SVG object, implicitly use svg namespace
print $svg->xmlify;

