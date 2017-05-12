#!/usr/bin/perl
use strict;
use warnings;

use SVG::Rasterize;
use SVG;

my $rasterize;
my $svg;

$svg = SVG->new;
$svg->path('stroke'            => 'yellow',
	   'stroke-width'      => 2,
	   'stroke-linejoin'   => 'bevel',
	   'stroke-dasharray'  => '7,3,3,3',
	   'stroke-dashoffset' => 8,
	   'd'                 => 'M20 15 l30 0 l10 80 Z',
	   'transform'       => 'rotate(-10)',
	   'fill'            => 'none');
$svg->path('stroke'            => 'cornflowerblue',
	   'stroke-width'      => 8,
	   'stroke-opacity'    => 0.7,
	   'stroke-miterlimit' => 2,
	   'd'                 => 'M10 10 L40 10 L50 90 Z',
	   'fill-opacity'      => 0.5);
$svg->path('stroke'         => 'red',
	   'stroke-width'   => 2,
	   'stroke-opacity' => 0.3,
	   'fill'           => 'none',
	   'd'              => 'M10,70c0,-10 15,-10 15,0 s15,10 15,0h20');

$rasterize = SVG::Rasterize->new;
$rasterize->rasterize(width => 100, height => 100, svg => $svg);
$rasterize->write(type => 'png', file_name => 'path.png');
