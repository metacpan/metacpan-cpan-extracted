#!/usr/bin/perl
use strict;
use warnings;

use SVG::Rasterize;
use SVG;

my $rasterize;
my $svg;

$svg = SVG->new;
$svg->path('stroke'       => 'cornflowerblue',
	   'stroke-width' => 2,
	   'd'            => 'M 125,75 a100,50 0 0,1 100,-50'.
                             'a100,50 0 1,1 -100,50 Z',
	   'fill'         => 'none',
	   'transform'    => 'translate(0, 0)');
$svg->path('stroke'       => 'cornflowerblue',
	   'stroke-width' => 2,
	   'd'            => 'M 125,75 a100,50 0 0,1 100,50'.
                             'a100,50 0 1,1 -100,-50 Z',
	   'fill'         => 'none',
	   'transform'    => 'translate(0, 0)');
$svg->path('stroke'       => 'red',
	   'stroke-width' => 6,
	   'd'            => 'M 125,75 a100,50 0 0,0 100,50',
	   'fill'         => 'none',
	   'transform'    => 'translate(0, 0)');

$svg->path('stroke'       => 'cornflowerblue',
	   'stroke-width' => 2,
	   'd'            => 'M 125,75 a100,50 0 0,1 100,-50'.
                             'a100,50 0 1,1 -100,50 Z',
	   'fill'         => 'none',
	   'transform'    => 'translate(400, 0)');
$svg->path('stroke'       => 'cornflowerblue',
	   'stroke-width' => 2,
	   'd'            => 'M 125,75 a100,50 0 0,1 100,50'.
                             'a100,50 0 1,1 -100,-50 Z',
	   'fill'         => 'none',
	   'transform'    => 'translate(400, 0)');
$svg->path('stroke'       => 'red',
	   'stroke-width' => 6,
	   'd'            => 'M 125,75 a100,50 0 0,1 100,50',
	   'fill'         => 'none',
	   'transform'    => 'translate(400, 0)');

$svg->path('stroke'       => 'cornflowerblue',
	   'stroke-width' => 2,
	   'd'            => 'M 125,75 a100,50 0 0,1 100,-50'.
                             'a100,50 0 1,1 -100,50 Z',
	   'fill'         => 'none',
	   'transform'    => 'translate(0, 250)');
$svg->path('stroke'       => 'cornflowerblue',
	   'stroke-width' => 2,
	   'd'            => 'M 125,75 a100,50 0 0,1 100,50'.
                             'a100,50 0 1,1 -100,-50 Z',
	   'fill'         => 'none',
	   'transform'    => 'translate(0, 250)');
$svg->path('stroke'       => 'red',
	   'stroke-width' => 6,
	   'd'            => 'M 125,75 a100,50 0 1,0 100,50',
	   'fill'         => 'none',
	   'transform'    => 'translate(0, 250)');

$svg->path('stroke'       => 'cornflowerblue',
	   'stroke-width' => 2,
	   'd'            => 'M 125,75 a100,50 0 0,1 100,-50'.
                             'a100,50 0 1,1 -100,50 Z',
	   'fill'         => 'none',
	   'transform'    => 'translate(400, 250)');
$svg->path('stroke'       => 'cornflowerblue',
	   'stroke-width' => 2,
	   'd'            => 'M 125,75 a100,50 0 0,1 100,50'.
                             'a100,50 0 1,1 -100,-50 Z',
	   'fill'         => 'none',
	   'transform'    => 'translate(400, 250)');
$svg->path('stroke'       => 'red',
	   'stroke-width' => 6,
	   'd'            => 'M 125,75 a100,50 0 1,1 100,50',
	   'fill'         => 'none',
	   'transform'    => 'translate(400, 250)');

$rasterize = SVG::Rasterize->new;
$rasterize->rasterize(width => 800, height => 525, svg => $svg);
$rasterize->write(type => 'png', file_name => 'arcs.png');
