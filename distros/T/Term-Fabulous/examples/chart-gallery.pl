#!/usr/bin/env perl

# Every chart widget of Term::Fabulous side by side, each with a little
# data of the kind it suits: values over time as lines, areas and bars,
# pairs of numbers as points, a distribution as a histogram, shares as a
# pie and a donut, counts around a circle as a polar area chart, profiles
# as a radar chart, and trends as sparklines. Ctrl+C quits.
#
#     perl examples/chart-gallery.pl

use v5.32;
use warnings;
use strict;
use utf8;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../lib/";

use Term::Fabulous;
use Term::Fabulous::Widget::AreaChart;
use Term::Fabulous::Widget::BarChart;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::DonutChart;
use Term::Fabulous::Widget::Histogram;
use Term::Fabulous::Widget::LineChart;
use Term::Fabulous::Widget::PieChart;
use Term::Fabulous::Widget::PolarAreaChart;
use Term::Fabulous::Widget::RadarChart;
use Term::Fabulous::Widget::ScatterPlot;
use Term::Fabulous::Widget::Sparkline;
use Term::Fabulous::Widget::Text;

use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

# Three rows of charts; every chart takes an equal share of its row.
sub chart_row (@charts) {
	my $row = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() }, child_gap => 3 } );
	$row->add_child(@charts);
	return $row;
}

my @months = qw(Jan Feb Mar Apr May Jun);

my $line = Term::Fabulous::Widget::LineChart->new(
	title  => 'LineChart',
	labels => \@months,
	series => [ { name => 'web', data => [ 12, 15, 14, 19, 23, 26 ] }, { name => 'app', data => [ 5, 8, 12, 13, 18, 24 ] } ],
);
my $area = Term::Fabulous::Widget::AreaChart->new(
	title   => 'AreaChart',
	labels  => \@months,
	stacked => 1,
	series  => [ { name => 'web', data => [ 12, 15, 14, 19, 23, 26 ] }, { name => 'app', data => [ 5, 8, 12, 13, 18, 24 ] } ],
);
my $bars = Term::Fabulous::Widget::BarChart->new(
	title  => 'BarChart',
	labels => [qw(Q1 Q2 Q3 Q4)],
	series => [ { name => '2025', data => [ 8, 11, 9, 14 ] }, { name => '2026', data => [ 10, 13, 12, 17 ] } ],
);
my $scatter = Term::Fabulous::Widget::ScatterPlot->new(
	title  => 'ScatterPlot',
	series => [ { name => 'cars', data => [ map { [ $_, 40 - 0.25 * $_ + 6 * sin( $_ * 7 ) ] } map { 20 + 4 * $_ } 0 .. 24 ] } ],
);

# Made-up exam scores: a bell curve around 62 points.
srand 3;
my @scores    = map { 62 + 9 * ( rand() + rand() + rand() + rand() - 2 ) } 1 .. 400;
my $histogram = Term::Fabulous::Widget::Histogram->new(
	title  => 'Histogram',
	series => [ { name => 'scores', data => \@scores } ],
);
my $pie = Term::Fabulous::Widget::PieChart->new(
	title => 'PieChart',
	data  => [ [ Photos => 56 ], [ Music => 20 ], [ System => 15 ], [ Other => 9 ] ],
);
my $donut = Term::Fabulous::Widget::DonutChart->new(
	title => 'DonutChart',
	data  => [ [ Europe => 412 ], [ America => 365 ], [ Asia => 290 ] ],
);

my $polar = Term::Fabulous::Widget::PolarAreaChart->new(
	title => 'PolarAreaChart',
	data  => [ [ Mon => 34 ], [ Tue => 41 ], [ Wed => 38 ], [ Thu => 45 ], [ Fri => 29 ], [ Sat => 9 ], [ Sun => 6 ] ],
);
my $radar = Term::Fabulous::Widget::RadarChart->new(
	title  => 'RadarChart',
	legend => 'none',
	labels => [qw(Speed Battery Screen Weight Price)],
	max    => 10,
	series => [ { name => 'A', data => [ 9, 6, 8, 5, 4 ] }, { name => 'B', data => [ 6, 9, 6, 9, 7 ] } ],
);

# Sparklines are one row high: a column of them, each under its name.
my $sparklines = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow() } } );
my @trend      = map { 50 + 30 * sin( $_ / 3 ) + 10 * sin( $_ * 1.3 ) } 0 .. 39;
$sparklines->add_child( Term::Fabulous::Widget::Text->new( text => 'Sparkline', text_color => [ 240, 240, 240, 255 ] ) );
foreach my $type (qw(line area bar)) {
	$sparklines->add_child(
		Term::Fabulous::Widget::Text->new( text => "type $type", text_color => [ 150, 160, 180, 255 ] ),
		Term::Fabulous::Widget::Sparkline->new( type => $type, values => \@trend, min => 0, max => 100 ),
	);
}

$root->add_child(
	chart_row( $line,      $area,  $bars, $scatter ),
	chart_row( $histogram, $pie,   $donut ),
	chart_row( $polar,     $radar, $sparklines ),
);

Term::Fabulous->new( width => 120, height => 40, root => $root )->run;
