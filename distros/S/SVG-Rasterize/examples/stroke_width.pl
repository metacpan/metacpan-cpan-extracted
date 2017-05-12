#!/usr/bin/perl
use strict;
use warnings;

use SVG;

my $svg = SVG->new(width => 100, height => 100);

$svg->circle(cx => 30, cy => 30, r => 20,
	     'stroke' => 'black',
	     'stroke-width' => 5,
	     'fill' => 'none');
$svg->circle(cx => 30, cy => 50, r => 10,
	     'stroke' => 'black',
	     'stroke-width' => 5,
	     'fill' => 'none',
	     transform => 'scale(2, 1)');
$svg->text('x' => 5, 'y' => 20, 'font-size' => 20,
	   transform => 'scale(4, 1)')->cdata('O');

print $svg->xmlify, "\n";
