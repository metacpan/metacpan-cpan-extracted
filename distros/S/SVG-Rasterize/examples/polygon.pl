#!/usr/bin/perl
use strict;
use warnings;

use SVG::Rasterize;
use SVG;

my $rasterize;
my $svg;
my $points;

$svg = SVG->new;
$svg->firstChild->attrib(viewBox => '0 0 1200 400');

$points = '350,75 379,161 469,161 397,215 '.
    '423,301 350,250 277,301 303,215 '.
    '231,161 321,161';
$svg->polygon('stroke'       => 'blue',
	      'stroke-width' => 10,
	      'fill'         => 'red',
	      'points'       => $points);
$points = '850,75  958,137.5 958,262.5 850,325 742,262.6 742,137.5';
$svg->polygon('stroke'       => 'blue',
	      'stroke-width' => 10,
	      'fill'         => 'lime',
	      'points'       => $points);

$rasterize = SVG::Rasterize->new;
$rasterize->rasterize(width => 480, height => 160, svg => $svg);
$rasterize->write(type => 'png', file_name => 'polygon.png');
