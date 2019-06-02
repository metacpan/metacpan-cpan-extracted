#!/usr/bin/env perl

# drafting grid for Inkle weaving

use strict;
use warnings;
use PDF::Cairo qw(in);
use PDF::Cairo::Box;
use Getopt::Long qw(:config no_ignore_case bundling);

my $color = "#999";
my $landscape = 0;
my $margin = 0.5;
my $paper;
my $output = "inkle-draft.pdf";
my $scale = 5;
GetOptions(
	"color|c=s" => \$color,
	"landscape|l" => \$landscape,
	"margin|m=f" => \$margin,
	"paper|p=s" => \$paper,
	"output|o=s" => \$output,
	"scale|s=f" => \$scale,
) or die <<EOF;
Usage: $0 [options]
  -c color (default: $color);
  -l (landscape page)
  -m margin (default (inches): $margin)
  -p papersize
  -o output.pdf
  -s scale (default: $scale)
EOF
$paper = "usletter" unless $paper;
$color = "#A4DDED" if $color eq "blue"; # non-photo blue
$output .= ".pdf" unless $output =~ /\.pdf$/;

my $pdf = PDF::Cairo->new(
	paper => $paper,
	landscape => $landscape,
	file => $output,
);
$pdf->scale($scale, $scale);

my $page = $pdf->pagebox;
$page->shrink(all => in($margin));
$page->scale(1/$scale);
my @rows = $page->grid(
	height => 12,
	width => 2,
	center => 1,
);

$pdf->strokecolor($color);
$pdf->linewidth(0.1);
$pdf->translate(-1, 0);
foreach my $row (@rows) {
	foreach my $cell (@$row) {
		$pdf->move($cell->x, $cell->y + 6);
		$pdf->rel_poly(0,1, 0,5, 1,1, 1,-1, 0,-5, -1,-1);
		$pdf->close->stroke;
		$pdf->move($cell->x + 1, $cell->y);
		$pdf->rel_poly(0,1, 0,5, 1,1, 1,-1, 0,-5, -1,-1);
		$pdf->close->stroke;
	}
	my $cell = pop(@$row);
	$pdf->move($cell->x + $cell->width, $cell->y + 6);
	$pdf->rel_poly(0,1, 0,5, 1,1, 1,-1, 0,-5, -1,-1);
	$pdf->close->stroke;
}
$pdf->stroke;
$pdf->write;
exit(0);
