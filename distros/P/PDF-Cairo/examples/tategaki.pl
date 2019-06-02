#!/usr/bin/env perl

# create a sheet of Japanese vertical-writing report paper.

use strict;
use warnings;
use PDF::Cairo qw(mm);
use PDF::Cairo::Box;
use Getopt::Long qw(:config no_ignore_case bundling);

my $papersize = 'usletter';
GetOptions(
	"paper|p=s" => \$papersize,
) or die "Usage: $0 [-p papersize]\n";

my $pdf = PDF::Cairo->new(
	file => 'tategaki.pdf',
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
	drawreportgrid($pdf, $sheet, 10, 20);
	$pdf->rect($sheet->bbox)->stroke;
}
$pdf->write;
exit 0;

# fill a box with a tategaki (vertical writing) grid, with
# a gutter on the right for visual spacing and furigana
#
sub drawreportgrid {
	my ($pdf,$box,$cols,$rows) = @_;
	my $kh = $box->{h}/$rows;
	my $kw = $kh;
	my $gw = ($box->{w} - ($kw * $cols))/$cols;
	my $dash = $kh/40;
	$pdf->save;
	$pdf->linewidth(0.1);
	# ah, this is how it's done...
	$pdf->linedash(-pattern => [$dash,$dash],-shift => $dash/2);

	foreach my $x (0..$cols - 1) {
		my $tmp2 = $box->{x} + $x * ($kw + $gw);
		$pdf->rect($tmp2,$box->{y},$kw,$kh * $rows);
		foreach my $y (1..$rows - 1) {
			$pdf->move($tmp2,$box->{y} + $y * $kh);
			$pdf->line($tmp2 + $kw,$box->{y} + $y * $kh);
		}
	}
	$pdf->stroke;
	$pdf->restore;
}
