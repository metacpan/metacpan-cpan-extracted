#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Sparkline;
use Term::Fabulous::Widget::Table;
use Term::Fabulous::Widget::Table::Mutator qw(sprintf_format);
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

# Daily closing prices of four stocks over 30 days.
srand 9;

sub prices ( $start, $drift ) {
	my $price = $start;
	return [ map { $price *= 1 + $drift + ( rand() - 0.5 ) * 0.04 } 1 .. 30 ];
}
my @stocks = (
	{ symbol => 'ACME', name => 'Acme Corp.',       prices => prices( 112,  0.004 ) },
	{ symbol => 'GLBX', name => 'Globex',           prices => prices( 48,  -0.003 ) },
	{ symbol => 'INIT', name => 'Initech',          prices => prices( 230,  0.001 ) },
	{ symbol => 'UMBR', name => 'Umbrella Holding', prices => prices( 75,   0.006 ) },
);
$_->{last}   = $_->{prices}[-1]                                 foreach @stocks;
$_->{change} = ( $_->{prices}[-1] / $_->{prices}[0] - 1 ) * 100 foreach @stocks;

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
	},
);

# A column whose cells are sparklines of the row's prices, green or red
# by the change over the month. Prices are far from 0, so the areas span
# the prices instead of growing from 0.
my $table = Term::Fabulous::Widget::Table->new(
	id           => 'stocks',
	row_id       => 'symbol',
	border       => 'Outer',
	column_lines => 'none',
	header_line  => 'none',
	stripe_color => '#1c2029',
	rows         => \@stocks,
	columns      => [
		{ key => 'symbol', title => 'Symbol' },
		{ key => 'name',   title => 'Name' },
		{ key => 'last',   title => 'Last',    type => 'number', mutator => sprintf_format('%.2f') },
		{ key => 'change', title => '30 days', type => 'number', mutator => sprintf_format('%+.1f%%') },
		{
			key        => 'prices',
			title      => 'Trend',
			width      => 'fixed(30)',
			sortable   => 0,
			filterable => 0,
			cell       => sub ($cell) {
				my $row = $cell->{row};
				return Term::Fabulous::Widget::Sparkline->new( type => 'area', zero => 0, values => $row->{prices}, color => $row->{change} >= 0 ? '#1baf7a' : '#e66767' );
			},
		},
	],
);
$root->add_child($table);

Term::Fabulous->new( root => $root, width => 90, height => 12 )->run;
