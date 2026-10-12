#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use List::Util qw(sum);
use Term::Fabulous::Static;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Table;
use Term::Fabulous::Widget::Table::Mutator qw(number percent);
use Term::Fabulous::Widget::Text;
use Clay::XS qw(sizing_fit CLAY_TOP_TO_BOTTOM);

my @sales = (
	{ product => 'Desk lamp',       units => 412,   revenue => 16_068.00 },
	{ product => 'Office chair',    units => 87,    revenue => 26_013.00 },
	{ product => 'Standing desk',   units => 34,    revenue => 20_366.00 },
	{ product => 'Monitor arm',     units => 156,   revenue => 9_204.00 },
	{ product => 'Cable organizer', units => 1_208, revenue => 4_820.00 },
);
my $total_revenue = sum( map { $_->{revenue} } @sales );
my @rows          = (
	(
		map {
			{ %$_, section => 0 }
		} @sales
	),
	{ product => 'Total', units => sum( map { $_->{units} } @sales ), revenue => $total_revenue, section => 1 },
);

my $report = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { height => sizing_fit() },
		child_gap        => 1,
	},
);

my $table = Term::Fabulous::Widget::Table->new(
	id           => 'sales',
	row_id       => 'product',
	scrollbar    => 0,    # nothing scrolls on paper
	hover        => 0,
	header_style => { text_color => '#e5c07b' },

	# The look: a block frame, and colors instead of grid lines.
	border       => 'Outer',
	column_lines => 'none',
	header_line  => 'none',
	stripe_color => '#1c2029',
	columns      => [
		{ key => 'section', visible => 0 },    # 0 for products, 1 for the totals row
		{ key => 'product', title   => 'Product' },
		{ key => 'units',   title   => 'Units',   type => 'number', mutator => number() },
		{ key => 'revenue', title   => 'Revenue', type => 'number', mutator => number( decimals => 2, suffix => ' EUR' ) },
		{
			key     => 'share',
			title   => 'Share',
			type    => 'number',
			value   => sub ($row) { $row->{revenue} / $total_revenue },
			mutator => percent( decimals => 1 ),
		},
	],
	rows => \@rows,
	sort => [ 'section', [ revenue => 'desc' ] ],    # the totals row last, the products by revenue
);
$table->set_row_style( Total => { border_top => 'Double', bold => 1 } );

$report->add_child(
	Term::Fabulous::Widget::Text->new( text => 'Sales, second quarter 2026', text_color => [ 230, 230, 230, 255 ] ),
	$table,
);

# Colors when STDOUT is a terminal, plain text in a pipe or a file.
Term::Fabulous::Static->new( root => $report, width => 72 )->print;
