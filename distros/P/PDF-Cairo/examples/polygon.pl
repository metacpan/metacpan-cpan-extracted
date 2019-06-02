#!/usr/bin/env perl

# draw regular polygons, test radius/inradius/edge options

use strict;
use warnings;
use PDF::Cairo qw(in);

my $pdf = PDF::Cairo->new(
	paper => 'usletter',
	wide => 1,
	file => 'polygon.pdf',
);

# test new scaling options:
#   edge => 1
#   inradius => 1
my %options = ();
$pdf->polygon(in(3), in(3), in(1), 3, %options)->fill;
$pdf->polygon(in(6), in(3), in(1), 4, %options)->fill;
$pdf->polygon(in(9), in(3), in(1), 5, %options)->fill;
$pdf->polygon(in(3), in(6), in(1), 7, %options)->fill;
$pdf->polygon(in(6), in(6), in(1), 8, %options)->fill;
$pdf->polygon(in(9), in(6), in(1), 13, %options)->fill;

$pdf->circle(in(3), in(3), in(1))->stroke;
$pdf->circle(in(6), in(3), in(1))->stroke;
$pdf->circle(in(9), in(3), in(1))->stroke;
$pdf->circle(in(3), in(6), in(1))->stroke;
$pdf->circle(in(6), in(6), in(1))->stroke;
$pdf->circle(in(9), in(6), in(1))->stroke;

$pdf->write;
exit;
