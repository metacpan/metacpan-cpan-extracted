#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Widget::AreaChart;
use Term::Fabulous::Widget::BarChart;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::LineChart;
use Clay::XS qw(sizing_grow sizing_percent CLAY_LEFT_TO_RIGHT_WRAP);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_LEFT_TO_RIGHT_WRAP,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 3,
		line_gap         => 1,
	},
);

my @wave  = map { 5 + 3 * sin( $_ / 3 ) + 1.2 * sin( $_ * 1.3 ) } 0 .. 30;
my %small = (
	x_axis => { visible => 0 },
	y_axis => { visible => 0, min => 0, max => 10 },
	layout => { sizing  => { width => sizing_percent(0.31), height => sizing_percent(0.31) } },
);

# Lines in each style a line can take...
foreach my $marker (qw(braille half quadrant sextant box)) {
	$root->add_child( Term::Fabulous::Widget::LineChart->new( %small, title => "line: $marker", marker => $marker, series => [ { name => $marker, data => \@wave } ] ) );
}

# ... an area in eighth blocks, and bars in quadrants and in blocks.
$root->add_child( Term::Fabulous::Widget::AreaChart->new( %small, title => 'area: block', series => [ { name => 'block', data => \@wave, color => '#d95926' } ] ) );
my @bars = map { $wave[ 3 * $_ ] } 0 .. 10;
$root->add_child( Term::Fabulous::Widget::BarChart->new( %small, title => 'bars: quadrant', marker => 'quadrant', series => [ { name => 'quadrant', data => \@bars, color => '#199e70' } ] ) );
$root->add_child( Term::Fabulous::Widget::BarChart->new( %small, title => 'bars: block',    series => [ { name => 'block', data => \@bars, color => '#199e70' } ] ) );
$root->add_child( Term::Fabulous::Widget::BarChart->new( %small, title => 'bars: braille',  marker => 'braille', series => [ { name => 'braille', data => \@bars, color => '#199e70' } ] ) );

Term::Fabulous->new( root => $root, width => 100, height => 32 )->run;
