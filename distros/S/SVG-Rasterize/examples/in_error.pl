#!/usr/bin/perl
use strict;
use warnings;

use SVG::Rasterize;
use SVG;

my $rasterize;
my $svg;
my $points;

$svg = SVG->new;

$svg->rect('width'        => 100,
	   'height'       => 130,
	   'fill'         => 'white');
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
$svg->path('stroke'         => 'red',
	   'stroke-width'   => 4,
	   'fill'           => 'none',
	   'd'              => 'M10,70 l0,-20 10,0 foo l 10 20');

$rasterize = SVG::Rasterize->new;
eval { $rasterize->rasterize(width => 100, height => 130, svg => $svg) };

if(SVG::Rasterize::Exception::InError->caught) {
    $rasterize->write(type => 'png', file_name => 'in_error.png');
}
