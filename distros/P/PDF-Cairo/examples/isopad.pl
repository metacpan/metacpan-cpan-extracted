#!/usr/bin/env perl

# graph paper for isometric drawing

use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case bundling);
use PDF::Cairo qw(in);
use PDF::Cairo::Box;
use Math::Trig;

my $usage = <<EOF;
Usage: $0 [-p papersize] [--landscape] [-o output.pdf] [-c color]
EOF

my $paper = 'usletter';
my $landscape = 0;
my $output = "isopad";
my $color = "#999";
my $gridsize = 0.5;
GetOptions(
	"paper|p=s" => \$paper,
	"landscape|l" => \$landscape,
	"output|o=s" => \$output,
	"color|c=s" => \$color,
	"gridsize|g=s" => \$gridsize,
) or die $usage;

$gridsize = in($gridsize);
$color = "#A4DDED" if $color eq "blue"; # non-photo blue
$output .= ".pdf" unless $output =~ /\.pdf$/;

my $dash = in(1/16);
my $dashlength = in(1/96);
my $dashshift = 2;

my $pdf = PDF::Cairo->new(
	paper => $paper,
	landscape => $landscape,
	file => $output,
);
$pdf->strokecolor($color);
$pdf->linewidth(in(1/128));

$pdf->rect($pdf->pagebox->bbox);
$pdf->clip;

my $page = $pdf->pagebox;
$page->expand(
	top => '100%',
	bottom => '100%',
);
my $x_grid = $gridsize * cos(deg2rad(30));
$page->width((int($page->width / $x_grid) + 1) * $x_grid);

foreach my $row ($page->slice(height => $gridsize)) {
	$pdf->move($row->xy);
	my $y_delta = $row->width * tan(deg2rad(30));
	$pdf->rel_line($row->width, $y_delta);
	$pdf->move($row->xy);
	$pdf->rel_line($row->width, - $y_delta);
	$pdf->stroke;
}
foreach my $col ($page->slice(width => $x_grid)) {
	$pdf->move($col->xy);
	$pdf->rel_line(0, $col->height);
	$pdf->stroke;
}

# draw half-grid
$pdf->linewidth($dashlength);
$pdf->strokecolor($color);
$pdf->linedash(-pattern => [$dashlength,$dash - $dashlength],
  -shift => $dashlength / $dashshift);
foreach my $row ($page->slice(height => $gridsize)) {
	$pdf->move($row->x, $row->y + $gridsize / 2);
	my $y_delta = $row->width * tan(deg2rad(30));
	$pdf->rel_line($row->width, $y_delta);
	$pdf->move($row->x, $row->y + $gridsize / 2);
	$pdf->rel_line($row->width, - $y_delta);
	$pdf->stroke;
}
foreach my $col ($page->slice(width => $x_grid)) {
	$pdf->move($col->x + $x_grid / 2, $col->y);
	$pdf->rel_line(0, $col->height);
	$pdf->stroke;
}
$pdf->write;
exit 0;
