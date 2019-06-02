#!/usr/bin/env perl

# test of showimage() scale/rotation options

use strict;
use warnings;
use PDF::API2::Lite;
use PDF::Cairo qw(in);
use PDF::Cairo::Box;

my $pdf = PDF::Cairo->new(
	paper => "usletter",
	landscape => 1,
	file => "images.pdf");

my $image = $pdf->loadimage("data/v04image002.png");
$pdf->showimage($image, in(1), in(1), scale => 0.25);

$pdf->strokecolor("blue");
$pdf->move(in(2), in(1));
$pdf->rel_line(- in(1), 0);
$pdf->rel_line(0, in(1));
$pdf->stroke;

$pdf->save;
$pdf->translate(in(4), in(4));
$pdf->showimage($image, in(1), in(1), x_scale => 0.1, y_scale => 0.2, rotate => -45);
$pdf->strokecolor("blue");
$pdf->move(in(2), in(1));
$pdf->rel_line(- in(1), 0);
$pdf->rel_line(0, in(1));
$pdf->stroke;
$pdf->restore;

$pdf->save;
$pdf->translate(in(7), in(2));
$pdf->showimage($image, in(1), in(1), scale => 0.1, rotate => 120);
$pdf->strokecolor("blue");
$pdf->move(in(2), in(1));
$pdf->rel_line(- in(1), 0);
$pdf->rel_line(0, in(1));
$pdf->stroke;
$pdf->restore;

$pdf->write;
exit;
