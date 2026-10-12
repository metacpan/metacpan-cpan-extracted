#!/usr/bin/env perl

# Term::Fabulous::Widget::LineChart: three series of monthly figures with
# the default look, smooth monotone curves and a title on the y axis.
# Move the mouse over a line or a legend entry to emphasize it; Ctrl+C
# quits.
#
#     perl examples/widgets/line-chart.pl

use v5.32;
use warnings;
use strict;
use utf8;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../../lib/";

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

my $chart = Term::Fabulous::Widget::LineChart->new(
	title  => 'Monthly active users',
	labels => [qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)],
	curve  => 'monotone',
	y_axis => { title => 'thousands' },
	series => [
		{ name => 'Web',     data => [ 120, 132, 151, 149, 170, 205, 261, 252, 196, 178, 164, 183 ] },
		{ name => 'iOS',     data => [ 82,  97,  108, 141, 166, 192, 228, 247, 223, 206, 214, 238 ] },
		{ name => 'Android', data => [ 31,  35,  41,  57,  62,  61,  74,  88,  95,  113, 128, 141 ] },
	],
);
$root->add_child($chart);

Term::Fabulous->new( width => 80, height => 24, root => $root )->run;
