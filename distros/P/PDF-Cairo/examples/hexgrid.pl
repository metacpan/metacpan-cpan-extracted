#!/usr/bin/env perl

# draw Traveller-style hex grids

use strict;
use warnings;
use PDF::Cairo qw(in regular_polygon);
use PDF::Cairo::Box;
use Getopt::Long qw(:config no_ignore_case bundling);
use Carp;

my $pdf = PDF::Cairo->new(
	paper => '17x22',
	tall => 1,
	file => 'hexgrid.pdf',
);

my $hex = regular_polygon(6);
my $smidge = sqrt($hex->{edge}**2 - $hex->{inradius}**2);

my $page = $pdf->pagebox;
$page->shrink(all => in(0.5));

# quadrant-scale
my $cols = 32;
my $rows = 40;

my $gridwidth = ($hex->{radius} * 2 + $hex->{edge}) * $cols / 2 + $smidge;
my $gridheight = $hex->{inradius} * (2 * $rows + 1);
my $radius;
if ($page->width / $gridwidth < $page->height / $gridheight) {
	$radius = $page->width / $gridwidth;
}else{
	$radius = $page->height / $gridheight;
}
my $fontsize = $radius / 3;

my $border = PDF::Cairo::Box->new(
	width => $gridwidth * $radius,
	height => $gridheight * $radius,
);
$page->center($border);
$pdf->translate($border->xy);

$pdf->linewidth(0.25);
$pdf->setfont($pdf->loadfont('Courier'), $fontsize);
my ($r, $c) = (0, 1);
foreach my $col (hexgrid($cols, $rows, $radius)) {
	$r = 1;
	foreach my $cell (@$col) {
		$pdf->polygon($cell->cxy, $radius, 6)->stroke;
		$pdf->move($cell->cx, $cell->y + $cell->height - $fontsize * 0.8);
		$pdf->print(sprintf("%02d%02d", $c, $r),
			align => 'center');
		$r++;
	}
	$c++;
}

$pdf->write;
exit;

# return a hex grid as an array of column references
#
sub hexgrid {
	my ($cols, $rows, $radius) = @_;
	croak("columns must be even!") if $cols % 2;
	croak("rows must be even!") if $rows % 2;
	my $hex = regular_polygon(6);
	my $cellwidth = 2 * $radius;
	my $cellheight = 2 * $radius * $hex->{inradius};
	my $xdelta = sqrt($hex->{edge}**2 - $hex->{inradius}**2) * $radius;
	my $ydelta = $radius * $hex->{inradius};
	my @result;
	foreach my $col (0..($cols - 1)) {
		my $x = $col * $radius * 2;
		$x -= $xdelta * $col;
		my @column;
		foreach my $row (reverse 0..($rows - 1)) {
			my $y = $row * $hex->{inradius} * $radius * 2;
			$y += $ydelta unless $col % 2;
			push(@column, PDF::Cairo::Box->new(
				x => $x,
				y => $y,
				width => $cellwidth,
				height => $cellheight,
			));
		}
		push(@result, \@column);
	}
	return @result;
}
