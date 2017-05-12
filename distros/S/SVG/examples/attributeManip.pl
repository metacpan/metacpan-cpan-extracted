#!/usr/bin/perl

#
# Attribute manipulations
#

use strict;
use warnings;

use SVG;

# Create an SVG object
# (c) 2003 Ronan Oger

my $svg = SVG->new(width=>200,height=>200);
$svg->title()->cdata('I am a title');

# Use explicit element constructor to generate a group element:

my $y = $svg->group(
    id    => 'group_y',
    style => { stroke=>'red', fill=>'green' }
);

# Add some circles to the group
$y->circle(cx=>100, cy=>100, r=>50, id=>'circle_in_group_y_1');
$y->circle(cx=>100, cy=>100, r=>50, id=>'circle_in_group_y_2');
$y->comment('This is a comment');
$y->circle(cx=>100, cy=>100, r=>50, id=>'circle_in_group_y_3');

# Now render the SVG object, while implicitly using the "svg" namespace.
print "\nfirst drawing\n";
print $svg->xmlify;

print "\n\nSet stroke to red on circle_in_group_y_1:\n";
my $node = $y->getElementByID('circle_in_group_y_1');
$node->setAttribute('stroke','red');
print $svg->xmlify;

print "\n\nSet stroke to green and undef the cx on circle_in_group_y_1\n";
$node->setAttributes({'stroke'=>'green',cx=>undef});
print $svg->xmlify, "\n";
