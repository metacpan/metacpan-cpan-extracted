#!/usr/bin/env perl

# simple test of svg() rendering using Image::CairoSVG and
# a recording surface.

use 5.016;
use strict;
use warnings;
use PDF::Cairo qw(in);

my $pdf = PDF::Cairo->new(
	paper => 'usletter',
	wide => 1,
	file => 'svg.pdf',
);

my $file = $ARGV[0] || "data/treasure-map.svg";
my $svg = PDF::Cairo->loadsvg($file);
$pdf->place($svg, in(1), in(4.5),
	scale => 0.5, 
	rotate => -45,
);

$pdf->strokecolor("blue");
$pdf->translate(in(1), in(4.5));
$pdf->move(in(1), 0);
$pdf->rel_line(- in(1), 0);
$pdf->rel_line(0, in(1));
$pdf->stroke;

$pdf->write;
exit;
