#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use List::Util qw(sum);
use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Table;
use Term::Fabulous::Widget::Table::Mutator qw(number);
use Term::Fabulous::Widget::Text;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my @budget = (
	{ id => 'hardware',   item => 'Hardware',   planned => 12_000, actual => 13_450 },
	{ id => 'software',   item => 'Software',   planned => 8_000,  actual => 7_200 },
	{ id => 'travel',     item => 'Travel',     planned => 5_000,  actual => 6_100 },
	{ id => 'training',   item => 'Training',   planned => 3_000,  actual => 0, cancelled => 1 },
	{ id => 'consulting', item => 'Consulting', planned => 15_000, actual => 14_250 },
	{ id => 'office',     item => 'Office',     planned => 2_000,  actual => 2_380 },
);
push @budget, {
	id      => 'total',
	item    => 'Total',
	planned => sum( map { $_->{planned} } @budget ),
	actual  => sum( map { $_->{actual} } @budget ),
};

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

my $money   = number( decimals => 0 );
my @columns = (
	{ key => 'item',    title => 'Item' },
	{ key => 'planned', title => 'Planned', type => 'number', mutator => $money },
	{ key => 'actual',  title => 'Actual',  type => 'number', mutator => $money },
	{
		key   => 'left',
		title => 'Left',
		type  => 'number',
		value => sub ($row) { $row->{planned} - $row->{actual} },

		# Signed amounts: a plus sign for money left, a minus for overruns.
		mutator    => [ $money, sub ( $text, $row ) { $text =~ /\A-/ || $text eq '0' ? $text : "+$text" } ],
		style      => { border_left => 'Heavy', row_lines => 'Dashed' },
		cell_style => sub ($cell) {
			return { text_color => '#e06c75', bold => 1 } if $cell->{value} < 0;
			return { text_color => '#98c379' };
		},
	},
);

my $table = Term::Fabulous::Widget::Table->new(
	id           => 'budget',
	row_id       => 'id',
	border       => 'Round',
	column_lines => 'Solid',
	header_line  => 'Heavy',
	line_color   => '#5c6370',
	stripe_color => '#1c2029',
	header_style => { background_color => '#2c313c', text_color => '#e5c07b' },
	row_style    => sub ( $row, $id ) { $row->{cancelled} ? { text_color => '#5c6370', italic => 1 } : undef },
	columns      => [ map { { sortable => 0, %$_ } } @columns ],    # the totals row stays at the bottom
	rows         => \@budget,
);

# Marks on single rows and cells.
$table->set_row_style( total => { border_top => 'Double', bold => 1, background_color => '#232a36' } );
$table->set_cell_style( travel => actual => { underline => 1 } );

$root->add_child(
	Term::Fabulous::Widget::Text->new( text => 'Project budget 2026 (EUR)', text_color => [ 230, 230, 230, 255 ], bold => 1 ),
	$table,
);

my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );
$ui->run;
