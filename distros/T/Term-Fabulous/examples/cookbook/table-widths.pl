#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Table;
use Term::Fabulous::Widget::Table::Mutator qw(number);
use Term::Fabulous::Widget::Text;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my @orders = (
	{ id => 1041, item => 'Desk lamp',   quantity => 2, price => 39.9, stars => 5, ship_to => "Ada Lovelace\nLondon", notes => 'Leave at the reception if nobody answers the door.' },
	{ id => 1042, item => 'Monitor arm', quantity => 1, price => 129,  stars => 4, ship_to => "Grace Hopper\nBoston", notes => 'Gift wrap.' },
	{
		id    => 1043, item => 'USB-C cable', quantity => 12, price => 8.5, stars => 3, ship_to => "Linus Torvalds\nPortland",
		notes => 'Customer asked for the black ones; call before shipping if out of stock.'
	},
);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

# A header cell of your own: a star and the title. The sort marker still
# follows it.
sub star_title ($column) {
	my $title = Term::Fabulous::Widget::Box->new( layout => { child_gap => 1 } );
	$title->add_child(
		Term::Fabulous::Widget::Text->new( text => "\x{2605}",     text_color => [ 229, 192, 123, 255 ] ),
		Term::Fabulous::Widget::Text->new( text => $column->title, bold => 1, text_color => [ 235, 238, 243, 255 ] ),
	);
	return $title;
}

my $table = Term::Fabulous::Widget::Table->new(
	id        => 'orders',
	row_id    => 'id',
	row_lines => 'Solid',

	# The table takes the whole width, so the grow column has room.
	layout  => { sizing => { width => sizing_grow() } },
	columns => [

		# Exactly 6 cells wide, padding included.
		{ key => 'id', title => '#', type => 'number', width => 'fixed(6)' },

		# The width the other columns leave over.
		{ key => 'item', title => 'Item', width => 'grow' },

		# A third of the table's width; the text wraps at spaces.
		{ key => 'notes', title => 'Notes', width => 'percent(33)' },

		# As wide as its widest line, but at least 16 cells; the text breaks
		# only at its newlines.
		{ key => 'ship_to', title => 'Ship to', width => 'fit(16)', wrap => 'newlines' },

		# Centered, the title too.
		{ key => 'quantity', title => 'Qty', type => 'number', align => 'center' },

		# Numbers are right-aligned; this title stays on the left.
		{ key => 'price', title => 'Price', type => 'number', header_align => 'left', mutator => number( decimals => 2 ) },

		# A widget as the title.
		{ key => 'stars', title => 'Rating', type => 'number', header => \&star_title, mutator => sub ( $stars, $row ) { "\x{2605}" x $stars } },
	],
	rows => \@orders,
);

my $help = Term::Fabulous::Widget::Text->new(
	text       => 'Resize the terminal: Item takes the width left over, Notes stays a third of the table and wraps.',
	text_color => [ 110, 120, 140, 255 ],
);
$root->add_child( $table, $help );

my $ui = Term::Fabulous->new( root => $root, width => 110, height => 24 );
$ui->interaction->set_focused_widget($table);
$ui->run;
