#!perl 
use 5.016;
use strict;
use warnings;
use Test::More;

use PDF::Cairo::Box;
use PDF::Cairo::Util qw(cm in mm regular_polygon);

diag( "\nTesting PDF::Cairo::Box $PDF::Cairo::Box::VERSION, Perl $], $^X" );

my $page1 = PDF::Cairo::Box->new(
	paper => 'usletter',
	wide => 1,
	y => -10,
);
cmp_ok ($page1->width, "==", 792, "landscape 8.5x11 page?");
cmp_ok ($page1->height, "==", 612, "landscape 8.5x11 page?");

my $box1 = PDF::Cairo::Box->new(
	width => in(2),
	height => cm(7),
	x => 17,
	y => 999,
);
cmp_ok ($box1->width, "==", 2 * 72, "two-inch wide box?");
cmp_ok ($box1->height, "==", 7 / 2.54 * 72, "7cm high box?");
isnt ($box1->iswide, "box not wide?");

my $bbox = PDF::Cairo::Box->bounds($page1, $box1);
is ($bbox->height, 999 + cm(7) + 10,
	"bounding box correct height?");

$page1->rel_move(0, 10);
cmp_ok ($page1->y, "==", 0, "box LLy relative move?");

$box1->size(200, 100);
$page1->center($box1);
is_deeply([$box1->cxy], [792 / 2, 612 / 2],
	"box centered to page?");
is_deeply([$box1->bbox], [(792 - 200) / 2, (612 - 100) / 2, 200, 100],
	"bbox correct after centering?");

my $page2 = $page1->fold;
is_deeply([$page2->size], [612, 792 / 2],
	"first fold?");
my $page3 = $page2->fold;
is_deeply([$page3->size], [792 / 2, 612 / 2],
	"second fold?");
my $page4 = $page1->fold(2);
is_deeply([$page4->size], [$page3->size],
	"double-fold same as 2x folds?");
my $page5 = $page3->unfold->unfold(2)->rotate;
is_deeply([$page5->size], [792, 612 * 2],
	"multiple unfold and rotate?");

my ($top, $bottom) = $page1->split(height => '10%');
cmp_ok($top->height, "==", 61.2,
	"10% split height?");
# numeric comparison of these two values fails; thanks, floating point!
cmp_ok(abs($page1->y + $page1->height * 0.9 - $top->y), "<", 0.00001,
	"10% split location?");
cmp_ok($top->height + $bottom->height, "==", $page1->height,
	"split adds up to 100%?");

# testing grid method also tests slice
my @grid = $page1->grid(height => 100, width => 100, center => 1);
my $cell_row3_col2 = [
	$page1->x + (792 % 100) / 2 + 100 * 2,
	$page1->y + $page1->height - (612 % 100) / 2 - 100 * 4,
];
is_deeply([$grid[3]->[2]->xy], $cell_row3_col2,
	"packed grid cells in correct location?");

#TODO:
#copy
#align
#move
#expand
#shrink
#scale

done_testing();
