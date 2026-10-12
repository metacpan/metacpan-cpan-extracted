#!/usr/bin/env perl

use v5.32;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::LineChart;
use Clay::XS qw(sizing_grow);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		sizing  => { width => sizing_grow(), height => sizing_grow() },
		padding => { left  => 2, right => 2, top => 1, bottom => 1 },
	},
);

# One label per category, one value per label in each series.
my $chart = Term::Fabulous::Widget::LineChart->new(
	title  => 'Average temperature',
	labels => [qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)],
	points => 1,
	y_axis => { title => '°C', format => '%d°' },
	series => [
		{ name => 'Lisbon', data => [ 11.6, 12.6, 14.9, 16.2, 18.6, 21.9, 23.8, 24.2, 22.6, 19.4, 15.2, 12.6 ] },
		{ name => 'Berlin', data => [  0.6,  2.3, 5.1,  10.2, 14.8, 17.9, 20.3, 19.7, 15.3, 10.5, 5.2,   1.8 ] },
		{ name => 'Oslo',   data => [ -2.9, -2.6, 1.0,  5.6,  11.0, 15.0, 17.6, 16.2, 11.6, 6.1,  1.4,  -2.3 ] },
	],
);
$root->add_child($chart);

Term::Fabulous->new( root => $root, width => 80, height => 24 )->run;
