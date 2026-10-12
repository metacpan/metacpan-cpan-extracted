#!/usr/bin/env perl

# Term::Fabulous::Widget::Histogram: the same observations measured four
# ways: the count per bin, the percent of all observations, the density
# (the area under the bars is 1), and cumulative percentages, which rise
# to 100% at the last bin. Ctrl+C quits.
#
#     perl examples/widgets/histogram-measures.pl

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
use Term::Fabulous::Widget::Histogram;

use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

# Made-up response times in milliseconds: a bell curve around 120.
srand 11;
my @durations = map { 120 + 40 * ( rand() + rand() + rand() + rand() - 2 ) } 1 .. 500;

sub histogram (%options) {
	return Term::Fabulous::Widget::Histogram->new( bin_width => 10, series => [ { name => 'requests', data => \@durations } ], %options );
}

sub chart_row (@charts) {
	my $row = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() }, child_gap => 4 } );
	$row->add_child(@charts);
	return $row;
}

$root->add_child(
	chart_row(
		histogram( title => 'measure count (default)' ),
		histogram( title => 'measure percent', measure => 'percent' ),
	),
	chart_row(
		histogram( title => 'measure density', measure => 'density', series => [ { name => 'requests', data => \@durations, color => '#199e70' } ] ),
		histogram( title => 'measure percent, cumulative', measure => 'percent', cumulative => 1, series => [ { name => 'requests', data => \@durations, color => '#199e70' } ] ),
	),
);

Term::Fabulous->new( width => 100, height => 30, root => $root )->run;
