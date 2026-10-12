#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::DonutChart;
use Term::Fabulous::Widget::PieChart;
use Clay::XS qw(sizing_grow);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		sizing    => { width => sizing_grow(), height => sizing_grow() },
		padding   => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap => 4,
	},
);

# Values with labels from a separate array; the largest slice first.
my $pie = Term::Fabulous::Widget::PieChart->new(
	title  => 'Disk usage',
	labels => [qw(Photos Music Documents System Other)],
	data   => [ 182, 64, 21, 48, 9 ],
	sort   => 'desc',
	legend => 'bottom',
);

# [ label, value ] pairs; slices below 5 % are folded into "Other",
# the legend shows amounts, and the middle says what the total is.
my $donut = Term::Fabulous::Widget::DonutChart->new(
	title         => 'Sales by region',
	data          => [ [ Europe => 412 ], [ 'North America' => 365 ], [ Asia => 290 ], [ 'South America' => 44 ], [ Africa => 21 ], [ Oceania => 18 ] ],
	other         => 0.05,
	other_label   => 'Rest of world',
	legend_values => 'value',
	format        => '%dk',
	center_text   => "1150k\norders",
	legend        => 'bottom',
);
$root->add_child( $pie, $donut );

Term::Fabulous->new( root => $root, width => 100, height => 26 )->run;
