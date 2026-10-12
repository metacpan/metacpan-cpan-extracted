#!/usr/bin/env perl

# Term::Fabulous::Widget::DonutChart: what the hole of a donut shows. By
# default the total; the share and label of the emphasized slice (under
# the mouse pointer, or chosen with highlight); or a center_text of your
# own. Move the mouse over a slice of the first donut; Ctrl+C quits.
#
#     perl examples/widgets/donut-chart-centers.pl

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
use Term::Fabulous::Widget::DonutChart;

use Clay::XS qw(sizing_grow);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		sizing    => { width => sizing_grow(), height => sizing_grow() },
		padding   => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap => 4,
	},
);

my @data = ( [ Rent => 1200 ], [ Food => 450 ], [ Car => 300 ], [ Fun => 220 ] );

sub donut (%options) {
	return Term::Fabulous::Widget::DonutChart->new( legend => 'bottom', format => '%d €', data => [ map { [@$_] } @data ], %options );
}

$root->add_child(
	donut( title => 'The total (default)' ),
	donut( title => 'highlight "Food"', highlight   => 'Food' ),
	donut( title => 'center_text',      center_text => "2170 €\nper month" ),
);

Term::Fabulous->new( width => 100, height => 22, root => $root )->run;
