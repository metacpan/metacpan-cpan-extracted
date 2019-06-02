#!/usr/bin/env perl

# create a sheet of kanji/kana practice paper.

use strict;
use warnings;
use PDF::Cairo qw(mm);
use PDF::Cairo::Box;
use Getopt::Long qw(:config no_ignore_case bundling);

my $papersize = 'usletter';
my $gridsize = 10;
GetOptions(
	"paper|p=s" => \$papersize,
	"grid|g=f" => \$gridsize,
) or die "Usage: $0 [-p papersize]\n";

my $pdf = PDF::Cairo->new(
	file => 'kanjigrid.pdf',
	paper => $papersize,
	landscape => 1,
);

my $paper = $pdf->pagebox;
my $page = PDF::Cairo::Box->new(paper => 'b5', landscape => 1);
$paper->center($page);
$pdf->linewidth(0.3);
$pdf->rect($page->bbox)->stroke;

foreach my $sheet ($page->split(width => '50%')) {
	$pdf->rect($sheet->bbox)->stroke;
	$sheet->shrink(all => mm(2.5));
	drawgrid($pdf, $sheet, mm($gridsize));
}
$pdf->write;
exit 0;

sub drawgrid {
	my ($pdf, $box, $gridsize) = @_;
	my @grid = $box->grid(
		width => $gridsize,
		height => $gridsize,
		center => 1,
	);
	$pdf->save;
	$pdf->linewidth(0.2);

	# half-grid lines
	$pdf->strokecolor('gray');
	foreach my $row (@grid) {
		foreach my $cell (@$row) {
			$pdf->move($cell->x + $cell->width / 2, $cell->y);
			$pdf->rel_line(0, $cell->height);
			$pdf->move($cell->x, $cell->y + $cell->height / 2);
			$pdf->rel_line($cell->width, 0);
		}
	}
	$pdf->stroke;

	# main grid
	$pdf->strokecolor('black');
	foreach my $row (@grid) {
		foreach my $cell (@$row) {
			$pdf->rect($cell->bbox);
		}
	}
	$pdf->stroke;
	$pdf->restore;
}
