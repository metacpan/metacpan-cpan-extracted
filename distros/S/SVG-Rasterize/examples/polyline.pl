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

$points = '50,375 '.
    '150,375 150,325 250,325 250,375 '.
    '350,375 350,250 450,250 450,375 '.
    '550,375 550,175 650,175 650,375 '.
    '750,375 750,100 850,100 850,375 '.
    '950,375 950,25 1050,25 1050,375 '.
    '1150,375';
$svg->polyline('stroke'       => 'navy',
	       'stroke-width' => 5,
	       'fill'         => 'none',
	       'points'       => $points);

$rasterize = SVG::Rasterize->new;
$rasterize->rasterize(width => 480, height => 160, svg => $svg);
$rasterize->write(type => 'png', file_name => 'polyline.png');
