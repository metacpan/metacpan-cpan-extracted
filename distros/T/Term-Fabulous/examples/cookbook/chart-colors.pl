#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Widget::BarChart;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::LineChart;
use Clay::XS qw(sizing_grow);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		sizing    => { width => sizing_grow(), height => sizing_grow() },
		padding   => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap => 2,
	},
);

my @months = qw(Jan Feb Mar Apr May Jun);

# A chart with a light background of its own: the theme follows it, so
# the text turns dark and the palette takes its steps for light ones.
$root->add_child(
	Term::Fabulous::Widget::LineChart->new(
		title            => 'Light background',
		title_align      => 'center',
		background_color => '#fcfcfb',
		layout           => { padding => { left => 1, right => 1, top => 1 } },
		labels           => \@months,
		legend           => 'bottom',
		x_axis           => { grid => 'dotted' },
		y_axis           => { grid => 'dotted' },
		series           => [ { name => 'North', data => [ 3, 5, 4, 7, 8, 9 ] }, { name => 'South', data => [ 4, 4, 6, 5, 7, 6 ] } ],
	)
);

# Colors of your own: a palette, one series' color, and the chrome.
$root->add_child(
	Term::Fabulous::Widget::BarChart->new(
		title        => 'Colors of your own',
		bordered     => 1,
		border_style => Term::Fabulous::Enum::BorderStyle->Round,
		border_color => '#3a4152',
		layout       => { padding => { left => 1, right => 1 } },
		labels       => \@months,
		palette      => [ '#61afef', '#c678dd', '#98c379' ],
		title_color  => '#e5c07b',
		label_color  => '#7f848e',
		grid_color   => '#2c313a',
		axis_color   => '#5c6370',
		series       => [
			{ name => 'Plan',   data => [ 5, 5, 6, 6, 7, 7 ] },
			{ name => 'Actual', data => [ 4, 6, 6, 5, 8, 9 ] },
			{ name => 'Target', data => [ 6, 6, 6, 6, 6, 6 ], type => 'line', color => '#e06c75', line_style => 'dashed' },
		],
	)
);

Term::Fabulous->new( root => $root, width => 100, height => 22 )->run;
