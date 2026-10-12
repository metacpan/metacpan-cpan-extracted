#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Histogram;
use Clay::XS qw(sizing_grow);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		sizing    => { width => sizing_grow(), height => sizing_grow() },
		padding   => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap => 4,
	},
);

# 600 exam scores from 0 to 100, most of them around 62 points.
srand 5;
my @scores = map { 62 + 14 * ( rand() + rand() + rand() - 1.5 ) * 1.4 } 1 .. 600;

# Bins chosen from the data...
$root->add_child(
	Term::Fabulous::Widget::Histogram->new(
		title  => 'Exam scores',
		x_axis => { title => 'points' },
		series => [ { name => 'Students', data => \@scores } ],
	)
);

# ... or fixed, 10 points wide from 0 to 100, counted up as percentages.
$root->add_child(
	Term::Fabulous::Widget::Histogram->new(
		title      => 'Share below ... points',
		bin_width  => 10,
		range      => [ 0, 100 ],
		measure    => 'percent',
		cumulative => 1,
		x_axis     => { title => 'points' },
		series     => [ { name => 'Students', data => \@scores, color => '#199e70' } ],
	)
);

Term::Fabulous->new( root => $root, width => 100, height => 20 )->run;
