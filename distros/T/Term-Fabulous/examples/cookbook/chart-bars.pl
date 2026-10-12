#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Widget::BarChart;
use Term::Fabulous::Widget::Box;
use Clay::XS qw(sizing_grow sizing_percent CLAY_TOP_TO_BOTTOM);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);
my $top = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_percent(0.6) }, child_gap => 4 } );
$root->add_child($top);

my @weekdays = qw(Mon Tue Wed Thu Fri);

# Several series side by side in each category, with their values.
$top->add_child(
	Term::Fabulous::Widget::BarChart->new(
		title        => 'Orders',
		labels       => \@weekdays,
		value_labels => 1,
		series       => [ { name => 'Shop', data => [ 18, 24, 21, 30, 34 ] }, { name => 'App', data => [ 12, 15, 19, 17, 26 ] } ],
	)
);

# The same kind of data on top of each other: the total and its parts.
$top->add_child(
	Term::Fabulous::Widget::BarChart->new(
		title   => 'Support tickets',
		labels  => \@weekdays,
		stacked => 1,
		series  => [
			{ name => 'Closed',  data => [ 9, 11, 10, 12, 14 ] },
			{ name => 'Pending', data => [ 3, 2,  4,  3,  5 ] },
			{ name => 'Open',    data => [ 5, 7,  3,  8,  6 ] },
		],
	)
);

# Horizontal bars leave room for long category names.
$root->add_child(
	Term::Fabulous::Widget::BarChart->new(
		title        => 'Top pages (views)',
		horizontal   => 1,
		value_labels => 1,
		labels       => [ '/pricing', '/docs/getting-started', '/blog/release-2-0', '/contact' ],
		series       => [ { name => 'Views', data => [ 8240, 6120, 4975, 1310 ], color => '#9085e9' } ],
	)
);

Term::Fabulous->new( root => $root, width => 100, height => 34 )->run;
