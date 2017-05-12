#!/usr/bin/perl
use strict;
use warnings;

use SVG::Rasterize;
use SVG;

my $rasterize;
my $svg;

$svg       = SVG->new;
$svg->line(x1 => 10, y1 => 10, x2 => 80, y2 => 20,
	   style => 'stroke:rgb(255, 0, 0);stroke-width:8',
	   'stroke-linecap' => 'round');
$svg->line(x1 => 50, y1 => 50, x2 => 100, y2 => 100,
	   style => 'stroke:rgb(0, 0, 100%)');
$svg->line(x1 => 100, y1 => 100, x2 => 500, y2 => 900,
	   transform => 'translate(40, 0) scale(0.1)',
	   stroke => 'cornflowerblue',
	   'stroke-width' => 20);

$rasterize = SVG::Rasterize->new;
$rasterize->rasterize(width => 100, height => 100, svg => $svg);
$rasterize->write(type => 'png', file_name => 'line.png');
