#!perl 
use 5.016;
use strict;
use warnings;
use Test::More;
use File::Temp;
use File::Compare;

use PDF::Cairo;
use PDF::Cairo::Util qw(in);

my $remove_tempdir = !defined $ARGV[0];
my $TMP = File::Temp->newdir("t02XXXXX", DIR => "t",
	CLEANUP => $remove_tempdir);
my $OUT = "$TMP/02.pdf";

diag( "\nTesting PDF::Cairo $PDF::Cairo::VERSION, Perl $], $^X" );

# generate a multi-page PDF with a small page size, to keep the
# size down.
#
my $pdf = PDF::Cairo->new(
	width => in(2),
	height => in(2),
	file => $OUT,
);

my @test_desc;

push(@test_desc, "blue filled rectangle");
$pdf->fillcolor('blue');
$pdf->rect(0, 0, in(2), in(2));
$pdf->fill;
$pdf->newpage;

push(@test_desc, "red stroked hexagon");
$pdf->strokecolor('red');
$pdf->polygon(in(1), in(1), in(0.5), 6);
$pdf->circle(in(1), in(1), in(0.5));
$pdf->stroke;
$pdf->newpage;

push(@test_desc, "fillstroked ellipse");
$pdf->fillcolor(0.3);
$pdf->strokecolor('crimson');
$pdf->linewidth(4);
$pdf->ellipse(0, in(1), in(1.5), in(0.8));
$pdf->fillstroke;
$pdf->newpage;

push(@test_desc, "strokefilled arc");
$pdf->linewidth(3);
$pdf->fillcolor('yellow');
$pdf->save;
$pdf->scale(in(1), in(1));
$pdf->translate(1, 1);
$pdf->arc(0, 0, 0.5, 0.8, 45, 180, 1);
$pdf->close;
$pdf->fillcolor('purple');
$pdf->restore;
$pdf->strokefill;
$pdf->newpage;

push(@test_desc, "bezier curves");
$pdf->move(10, 10);
$pdf->curve(20, 120, 40, 40, 140, 60);
$pdf->rel_curve(-10, 10, -40, 40, -100, -30);
$pdf->linedash([12, 4, 8], 2);
$pdf->linewidth(4);
$pdf->stroke;
$pdf->newpage;

push(@test_desc, "clipping path");
$pdf->poly(10,10, 30,10, 70,5, 100,40, 140,140, 80,100, 20,60);
$pdf->close;
$pdf->linewidth(2)->strokecolor('lightgray')->stroke(preserve => 1);
$pdf->clip;
$pdf->translate(in(1), in(1))->rotate(-60);
$pdf->polygon(0, 0, in(0.5), 12, edge => 1);
$pdf->fill;
$pdf->newpage;

push(@test_desc, "misc: linecap, line, rel_poly, rel_rect, roundrect, rel_roundrect");
$pdf->linewidth(4);
$pdf->move(10, 10)->line(100, 10)->stroke;
$pdf->linecap('round');
$pdf->move(10, 20)->line(100, 20)->stroke;
$pdf->linecap('square');
$pdf->move(10, 30)->line(100, 30)->stroke;
$pdf->move(10, 40)->rel_rect(10, 10, 80, 20)->fill;
$pdf->move(10, 80)->rel_poly(10,10, 80,0, 0,20, -80,0, 0,-20)->close->stroke;
$pdf->roundrect(120, 10, 20, 50)->fill;
$pdf->linewidth(0.1);
$pdf->move(130, 110)->rel_roundrect(-10, -25, 20, 50, 10)->stroke;
$pdf->newpage;

push(@test_desc, "simple text");
my $font1 = $pdf->loadfont("data/Karla-Regular.ttf");
$pdf->setfont($font1, 12);
my $page = $pdf->pagebox;
$pdf->move($page->xy)->rel_move(10, 10)->print("Hamburgefontsiv");
$pdf->setfontsize(18);
$pdf->move($page->cxy)->rel_move(0, -18 * $font1->capheight(1) / 2);
$pdf->print("XYZZY", align => 'center');
$pdf->move($page->cxy)->rel_line(in(1), 0)->stroke;
$pdf->move(0, 0)->rel_move($page->width, $page->height);
$pdf->rel_move(-2, -$font1->ascender(1) * 18);
$pdf->print("2.718281828", align => 'right');
$pdf->setfont($pdf->loadfont("data/Karla-Italic.ttf"), 24);
$pdf->newpage;

# TODO: note that font and size are getting carried over from
# the previous page. Review PDF spec to see if that's expected
# behavior!
push(@test_desc, "text with rotation; textpath with x/y scaling, skew");
$pdf->save;
$pdf->translate(in(1), in(1));
foreach my $i (0..7) {
	$pdf->fillcolor(($i+2)/12);
	$pdf->rotate(360/8);
	$pdf->move(0,0)->print("--->", valign => 'center');
}
$pdf->restore;
$pdf->linejoin('round');
$pdf->move(10, 10)->scale(0.8, 1.4)->skew(2, 0)->textpath("Karla-Ital-24");
$pdf->linewidth(0.5)->stroke;
$pdf->newpage;

push(@test_desc, "text vertical shift");
my $font2 = $pdf->loadfont("data/icons.ttf");
$pdf->setfont($font2, 32);
$pdf->move(20, 60);
$pdf->print("A")->print("B", shift => 2)->print("A")->print("B", shift => -2);
$pdf->newpage;

push(@test_desc, "loadimage/showimage");
my $image = $pdf->loadimage("data/v04image002.png");
$pdf->showimage($image, $page->xy, scale => 0.04);
$pdf->showimage($image, $page->x + $page->width, $page->y,
	scale => 0.04, align => 'right');
$pdf->showimage($image, $page->x, $page->y + $page->height,
	scale => 0.04, valign => 'top');
$pdf->showimage($image, $page->x + $page->width, $page->y + $page->height,
	scale => 0.04, align => 'right', valign => 'top');
$pdf->showimage($image, $page->cxy, x_scale => 0.04, y_scale => 0.1,
	center => 1, rotate => 180);
$pdf->newpage;

push(@test_desc, "loadsvg/place");
my $svg = $pdf->loadsvg("data/treasure-map.svg");
$pdf->place($svg, $page->xy, scale => 0.08);
$pdf->place($svg, $page->x + $page->width, $page->y,
	scale => 0.08, align => 'right');
$pdf->place($svg, $page->x, $page->y + $page->height,
	scale => 0.08, valign => 'top');
$pdf->place($svg, $page->x + $page->width, $page->y + $page->height,
	scale => 0.08, align => 'right', valign => 'top');
$pdf->place($svg, $page->cxy, x_scale => 0.08, y_scale => 0.2,
	center => 1, rotate => 180);
$pdf->newpage(width => in(5), height => in(3)); # new size, for next test

push(@test_desc, "page size: 3x5");
$pdf->setfont($font1, 44);
$pdf->move(in(0.5), in(2.5));
$pdf->fillcolor('orange');
$pdf->print("3x5-inch page");
$pdf->newpage(paper => 'b7');
push(@test_desc, "page size: b7");
$page = $pdf->pagebox;
$pdf->move(in(0.5), $page->height - in(0.5));
$pdf->print("b7 page");
$pdf->newpage;
push(@test_desc, "page size: remains b7");
$pdf->fillcolor('green');
$pdf->move(in(0.5), $page->height - in(0.5));
$pdf->print("still b7");
$pdf->newpage(width => in(2), height => in(2));

$pdf->write;
ok(-s $OUT, "wrote PDF to disk?");

# if poppler is installed, we can compare the above output to
# a reference PDF by rendering both to PNG.
#
SKIP: {
	my $tmp = `pdftocairo -v 2>&1` || '';
	skip("need poppler's pdftocairo to compare images")
		unless $tmp =~ /pdftocairo/;
	my $PDFTOCAIRO = "pdftocairo -png -r 200";
	system("$PDFTOCAIRO t/02-cairo.pdf $TMP/ref");
	system("$PDFTOCAIRO $OUT $TMP/02");
	foreach my $i (1..@test_desc) {
		$i = sprintf("%02d", $i);
		my $test = "page $i: " . shift(@test_desc);
		subtest $test => sub {
			plan tests => 3;
			ok(-s "$TMP/ref-$i.png", "reference page non-empty?");
			ok(-s "$TMP/02-$i.png", "page non-empty?");
			ok(compare("$TMP/02-$i.png", "$TMP/ref-$i.png") == 0,
				"page matches reference?");
		}
	}
}

done_testing();
