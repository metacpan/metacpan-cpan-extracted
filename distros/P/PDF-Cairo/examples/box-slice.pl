#!/usr/bin/env perl

# test the options for distributing cells inside a slice/grid

use strict;
use warnings;
use PDF::Cairo qw(cm);
use PDF::Cairo::Box;

my $pdf = PDF::Cairo->new(
	paper => 'usletter',
	landscape => 1,
	file => 'box-slice.pdf',
);

my $box = PDF::Cairo::Box->new(
	width => cm(7),
	height => cm(7),
);

# default: no packing
$pdf->save->translate(cm(2), cm(14));
$pdf->move($box->x, $box->y - 10)->print("(default)");
drawgrid($pdf, $box, cm(2), cm(2));
$pdf->restore;

# packed top left
$pdf->save->translate(cm(10), cm(14));
$pdf->move($box->x, $box->y - 10)->print("xpack => 'left', ypack => 'top'");
drawgrid($pdf, $box, cm(2), cm(2), xpack => 'left', ypack => 'top');
$pdf->restore;

# center
$pdf->save->translate(cm(18), cm(14));
$pdf->move($box->x, $box->y - 10)->print("center => 1");
drawgrid($pdf, $box, cm(2), cm(2), center => 1);
$pdf->restore;

# x-packed center
$pdf->save->translate(cm(2), cm(6));
$pdf->move($box->x, $box->y - 10)->print("xpack => 'center'");
drawgrid($pdf, $box, cm(2), cm(2), xpack => 'center');
$pdf->restore;

# y-packed bottom
$pdf->save->translate(cm(10), cm(6));
$pdf->move($box->x, $box->y - 10)->print("ypack => 'bottom'");
drawgrid($pdf, $box, cm(2), cm(2), ypack => 'bottom');
$pdf->restore;

# center right
$pdf->save->translate(cm(18), cm(6));
$pdf->move($box->x, $box->y - 10)->print("xpack => 'right', ypack => 'center'");
drawgrid($pdf, $box, cm(2), cm(2), xpack => 'right', ypack => 'center');
$pdf->restore;

$pdf->write;
exit 0;

sub drawgrid {
	my ($pdf, $box, $width, $height, %options) = @_;
	$pdf->linewidth(0.25);
	$pdf->rect($box->bbox)->stroke;
	my @grid = $box->grid(
		width => $width,
		height => $height,
		%options,
	);
	foreach my $row (@grid) {
		foreach my $cell (@$row) {
			$pdf->rect($cell->bbox)->stroke;
		}
	}
	# create a new bounding box without the whitespace
	$pdf->linewidth(1);
	$pdf->strokecolor('blue');
	$pdf->rect(PDF::Cairo::Box::bounds(map(@$_, @grid))->bbox)->stroke;
}
