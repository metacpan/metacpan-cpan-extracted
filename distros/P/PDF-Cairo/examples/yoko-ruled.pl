#!/usr/bin/env perl

# create a sheet of Japanese-style notepaper (shamelessly swiped from
# a Kyokuto notebook many years ago)

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
	file => "yoko-ruled.pdf",
	paper => $papersize,
	landscape => 1,
);

my $paper = $pdf->pagebox;
my $page = PDF::Cairo::Box->new(paper => 'b5', landscape => 1);
$paper->center($page);
$pdf->linewidth(0.3);
$pdf->rect($page->bbox)->stroke;

my $font = $pdf->loadfont('Helvetica');
foreach my $sheet ($page->split(width => '50%')) {
	$pdf->rect($sheet->bbox)->stroke;
	$sheet->shrink(all => mm(2));
	drawruled($pdf, $sheet, mm(7), $font);
}
$pdf->write;
exit 0;

sub drawruled {
	my ($pdf, $box, $gridsize, $font) = @_;
	my $rows = int($box->height / $gridsize);
	my $width = int($box->width / $gridsize) * $gridsize;

	$pdf->linewidth(0.2);

	my $content = PDF::Cairo::Box->new(
		width => $width,
		height => $gridsize * $rows,
	);
	$box->center($content);
	my @rows = $content->slice(height => $gridsize);

	my $tmp = shift(@rows);
	my @tmp = $tmp->slice(width => 4 * $gridsize);
	my $date = pop(@tmp);
	$pdf->move($date->xy);
	$pdf->rel_line($date->width, 0);
	$pdf->stroke;
	$pdf->setfont($font, $gridsize / 4);
	$pdf->move($date->x, $date->y - $font->ascender * $gridsize / 4 - 1);
	$pdf->print("  DATE");

	my $header = shift(@rows);
	$pdf->setfont($font, $gridsize / 3);
	$pdf->move($header->x, $header->y + 3);
	$pdf->print("  THEME / No.");

	$pdf->move($header->xy);
	$pdf->rel_line($header->width, 0)->stroke;
	$pdf->move($header->x, $header->y + 2);
	$pdf->rel_line($header->width, 0)->stroke;

	my @dots = $header->slice(width => $gridsize);
	shift(@dots);
	my $count = 0;
	foreach my $dot (@dots) {
		if (++$count % 5 == 0) {
			$pdf->circle($dot->x, $dot->y - 0.8, 0.6)->fill;
		}else{
			$pdf->circle($dot->x, $dot->y - 0.5, 0.3)->fill;
		}
	}

	my $footer = pop(@rows);
	$pdf->move($footer->xy);
	$pdf->rel_line($footer->width, 0)->stroke;
	@dots = $footer->slice(width => $gridsize);
	shift(@dots);
	$count = 0;
	foreach my $dot (@dots) {
		if (++$count % 5 == 0) {
			$pdf->circle($dot->x, $dot->y + 0.8, 0.6)->fill;
		}else{
			$pdf->circle($dot->x, $dot->y + 0.5, 0.3)->fill;
		}
	}

	$pdf->linewidth(0.1);
	$count = 0;
	foreach my $row (@rows) {
		$pdf->move($row->xy);
		$pdf->rel_line($row->width, 0)->stroke;
		if (++$count % 5 == 0) {
			$pdf->circle($row->x - 0.6, $row->y, 0.6)->fill;
			$pdf->circle($row->x + $row->width + 0.6, $row->y, 0.6)->fill;
		}
	}
}
