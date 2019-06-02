#!/usr/bin/env perl

# quick test of using textpath() method to load font outlines
# as paths

use strict;
use warnings;
use PDF::Cairo qw(in);

my $pdf = PDF::Cairo->new(
	paper => 'usletter',
	landscape => 1,
	file => 'textpath.pdf',
);

my $font = $pdf->loadfont('Courier-BoldOblique');
$pdf->setfont($font, 144);
$pdf->move(in(1), in(5));
$pdf->textpath('xyzzy');
$pdf->linewidth(3);
$pdf->fillcolor('red');
$pdf->fillstroke;

#dump the outline path
#
$pdf->move(0, 0);
$pdf->textpath('X');
my @path = $pdf->path;

# automatically process a path
#
$pdf->translate(in(2), in(2));
$pdf->path(@path);
$pdf->stroke;

# manually process a path
#
$pdf->translate(in(2), 0);
while (@path) {
	my $op = shift(@path);
	my $val = shift(@path);
	$pdf->$op(@$val);
	print "$op";
	while (@$val) {
		printf(" %.3f,%.3f", shift(@$val), shift(@$val));
	}
	print "\n";
}
$pdf->fill;

$pdf->write;
exit;
