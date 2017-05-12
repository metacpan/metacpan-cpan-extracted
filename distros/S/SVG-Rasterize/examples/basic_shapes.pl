#!/usr/bin/perl
use strict;
use warnings;

use SVG::Rasterize;
use SVG;

my $rasterize;
my $svg;

$svg = SVG->new;
$svg->rect('x'            => 10,
	   'y'            => 70,
	   'width'        => 30,
	   'height'       => 20,
	   'stroke'       => 'navy',
	   'stroke-width' => 2,
	   'fill'         => 'yellow');
$svg->rect('x'            => 10,
	   'y'            => 70,
	   'width'        => 30,
	   'height'       => 20,
	   'stroke'       => 'navy',
	   'stroke-width' => 2,
	   'fill'         => 'yellow');
$svg->rect('width'        => 30,
	   'height'       => 20,
	   'rx'           => 10,
	   'ry'           => 5,
	   'stroke'       => 'purple',
	   'stroke-width' => 5,
	   'fill'         => 'none',
	   'transform'    => 'translate(50, 60) rotate(-30)');
$svg->circle('stroke'       => 'yellow',
	     'stroke-width' => 2,
	     'cx'           => 20,
	     'cy'           => 20,
	     'r'            => 15,
	     'fill'         => 'cornflowerblue');
$svg->rect('x'            => 5,
	   'y'            => 5,
	   'width'        => 30,
	   'height'       => 30,
	   'stroke'       => 'red',
	   'stroke-width' => 2,
	   'stroke-dasharray'  => '7,3,3,3',
	   'stroke-dashoffset' => 8,
	   'fill'         => 'none');
$svg->ellipse('stroke'       => 'navy',
	      'stroke-width' => 2,
	      'cx'           => 50,
	      'cy'           => 50,
	      'rx'           => 10,
	      'ry'           => 40,
	      'fill'         => 'none');

$rasterize = SVG::Rasterize->new;
$rasterize->rasterize(width => 100, height => 100, svg => $svg);
$rasterize->write(type => 'png', file_name => 'basic_shapes.png');
