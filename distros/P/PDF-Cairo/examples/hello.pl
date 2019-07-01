#!/usr/bin/env perl

# fill a page with customizable "hello my name is..." stickers

use 5.016;
use utf8::all;
use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case bundling);
use PDF::Cairo qw(in);
use PDF::Cairo::Box;

my $textfont = 'Helvetica-Bold';
my $textcolor = 'black';
my %opt = (
	color => '',
	bgcolor => '#dd0000',
	font => '',
	height => in(2.5),
	landscape => 0,
	output => "hello.pdf",
	paper => 'usletter',
	width => in(3.5),
);
my @lines;
GetOptions(\%opt,
	"color|c=s",
	"bgcolor|b=s",
	"font|f=s",
	"height|h=f",
	"landscape|l",
	"output|o=s",
	"paper|p=s",
	"width|w=f",
	# store the current font and color for each argument
	"<>" => sub { push(@lines, [ 
		shift, $opt{color} || $textcolor, $opt{font} || $textfont,
	])},
) or die <<EOF;
Usage: $0 [options] [[-f font] [-c color] name|hello|mynameis]
    -b bgcolor  (#DD0000)
    -h height   (180 points)
    -w width    (252 points)
    -o output   (hello.pdf)
    -p paper    (usletter)
    -l (landscape orientation)

There can be up to three lines of text, each in its own font and color.
By default, the first line is "HELLO", the second is "MY NAME IS", and
the third is empty. The first argument will be printed in the large
white box (default color 'black'), and additional arguments will
replace the "HELLO" and "MY NAME IS", respectively (default color
'white').
EOF
$opt{output} .= ".pdf" unless $opt{output} =~ /\.pdf$/;

my $hello = PDF::Cairo->recording(
	width => $opt{width},
	height => $opt{height},
);

$hello->roundrect(0, 0, $opt{width}, $opt{height});
$hello->fillcolor($opt{bgcolor});
$hello->fill;

my $box = $hello->pagebox->shrink(top => 6, bottom => 14);
my ($top, $bottom) = $box->split(height => '45%');

$hello->fillcolor('white');
$hello->rect($bottom->bbox);
$hello->strokecolor($opt{bgcolor});
$hello->linewidth(1);
$hello->fillstroke;
$bottom->shrink(all => 2);

my ($line1, $line2) = $top->split(height => '75%');
$line1->shrink(left => 4, right => 4, botton => 2);
$line2->shrink(left => 4, right => 4, bottom => 2);

my @text = ('', 'HELLO', 'MY NAME IS');
my $once = 1;
foreach my $line ($bottom, $line1, $line2) {
	my $text = shift(@text);
	if (@lines) {
		my $tmp = shift(@lines);
		($text, $textcolor, $textfont) = @$tmp;
	}else{
		$textcolor = $opt{color} if $opt{color};
		$textfont = $opt{font} if $opt{font};
	}
	if ($text) {
		my $font = $hello->loadfont($textfont);
		$hello->setfont($font);
		$hello->fillcolor($textcolor);
		$hello->autosize($text, $line);
		$hello->move($line->cxy);
		$hello->print($text, center => 1);
	}
	$textcolor = 'white' if $once;
	$once = 0;
}

# place as many copies of the sticker as can fit on the paper
#
my $pdf = PDF::Cairo->new(
	paper => $opt{paper},
	wide => $opt{landscape},
	file => $opt{output},
);
my @grid = $pdf->pagebox->grid(
	width => $opt{width},
	height => $opt{height},
);
foreach my $row (@grid) {
	foreach my $cell (@$row) {
		$pdf->place($hello, $cell->xy);
	}
}
$pdf->write;
exit;
