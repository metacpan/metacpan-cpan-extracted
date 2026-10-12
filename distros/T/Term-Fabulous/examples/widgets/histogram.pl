#!/usr/bin/env perl

# Term::Fabulous::Widget::Histogram: how long 2000 requests to two
# servers took, binned automatically and drawn over each other. Ctrl+C
# quits.
#
#     perl examples/widgets/histogram.pl

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

use Clay::XS qw(sizing_grow);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		sizing  => { width => sizing_grow(), height => sizing_grow() },
		padding => { left  => 2, right => 2, top => 1, bottom => 1 },
	},
);

# Made-up response times in milliseconds: a bell curve around $typical.
srand 7;

sub durations ( $count, $typical, $spread ) {
	return map { $typical + $spread * ( rand() + rand() + rand() + rand() - 2 ) } 1 .. $count;
}

my $chart = Term::Fabulous::Widget::Histogram->new(
	title  => 'Response times',
	x_axis => { title => 'milliseconds' },
	y_axis => { title => 'requests' },
	series => [
		{ name => 'eu-west', data => [ durations( 1000, 120, 40 ) ] },
		{ name => 'us-east', data => [ durations( 1000, 175, 50 ) ] },
	],
);
$root->add_child($chart);

Term::Fabulous->new( width => 80, height => 24, root => $root )->run;
