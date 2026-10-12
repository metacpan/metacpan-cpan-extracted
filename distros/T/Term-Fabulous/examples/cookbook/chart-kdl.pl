#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Layout;

my $layout = Term::Fabulous::Layout->new( string => <<'KDL' );
use Term::Fabulous::Widget::Box as Box
use Term::Fabulous::Widget::BarChart as BarChart
use Term::Fabulous::Widget::DonutChart as DonutChart

Box "root" {
	layout gap=4
	sizing width=grow height=grow
	padding left=2 right=2 top=1 bottom=1

	BarChart "sales" {
		sizing width="percent(60)" height=grow
		title "Sales and returns"
		labels "Q1" "Q2" "Q3" "Q4"
		value_labels #true
		y_axis title="units" grid="dotted"
		series "Sold" color="#3987e5" { data 90 140 165 190; }
		series "Returned" color="#e66767" { data 14 11 17 12; }
		series "Trend" type="line" line_style="dashed" color="#c98500" {
			data 90 140 165 190
			transform "moving_average" 2
		}
	}

	DonutChart "channels" {
		title "Sold by channel"
		legend "bottom"
		slice "Shop" 312
		slice "Partners" 158
		slice "Phone" 97
	}
}
KDL

my $root = $layout->build;

# Data from the program goes to the widgets the layout named.
$root->find_by_id('channels')->set_value( Web => 431 );

Term::Fabulous->new( root => $root, width => 100, height => 22 )->run;
