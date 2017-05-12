#!/usr/bin/perl
use strict;
use warnings;

use SVG::Rasterize;
use SVG;

my $rasterize;
my $svg;
my $engine;

$svg = SVG->new;
$svg->firstChild->attrib(viewBox => "0 0 1200 600");

$svg->path('stroke'       => 'yellow',
	   'stroke-width' => 10,
	   'fill'         => 'none',
	   'd'            => 'M200,300 L400,50 L600,300 '.
	                     'L800,550 L1000,300');
$svg->path('stroke'       => 'cornflowerblue',
	   'stroke-width' => 20,
	   'fill'         => 'none',
	   'd'            => 'M200,300 Q400,50 600,300 T1000,300');

$rasterize = SVG::Rasterize->new;
$rasterize->rasterize(width => 240, height => 120, svg => $svg);
$rasterize->write(type => 'png', file_name => 'qbezier.png');
