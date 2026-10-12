#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Table;
use Term::Fabulous::Widget::Table::Filter;
use Term::Fabulous::Widget::Table::Mutator qw(date lookup number);
use Term::Fabulous::Widget::Text;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my $F = 'Term::Fabulous::Widget::Table::Filter';

my @invoices = (
	{ invoice => 'A-1001', customer => 'Babbage Ltd',      placed => '2026-04-14', status => 'p', total => 1250.00, paid => 1250.00 },
	{ invoice => 'A-1002', customer => 'Analytical Works', placed => '2026-04-29', status => 'd', total => 480.50,  paid => 0 },
	{ invoice => 'A-1003', customer => 'Byron & Sons',     placed => '2026-05-03', status => 'o', total => 2300.00, paid => 1000.00 },
	{ invoice => 'A-1004', customer => 'Hollerith Ltd',    placed => '2026-05-11', status => 'o', total => 99.90,   paid => 0 },
	{ invoice => 'A-1005', customer => 'Countess Supply',  placed => '2026-05-20', status => 'p', total => 640.00,  paid => 640.00 },
	{ invoice => 'A-1006', customer => 'Boole Partners',   placed => '2026-05-27', status => 'd', total => 1720.00, paid => 200.00 },
	{ invoice => 'A-1007', customer => 'Jacquard Looms',   placed => '2026-06-01', status => 'o', total => 315.25,  paid => 0 },
);

# Key 1 to 5 sets one of these filters under the name 'chosen'; key 0
# removes it.
my @choices = (
	[ 'Totals of 1,000 or more' => $F->new( column => 'total',  op => '>=', value => 1000 ) ],
	[ 'Placed in May 2026'      => $F->new( column => 'placed', op => '=',  value => '2026-05' ) ],
	[
		'Open or overdue, totals from 100 to 2,000' => $F->all(
			$F->new( column => 'status', op => 'in', value => [ 'open', 'overdue' ], on => 'display' ),
			$F->new( column => 'total',  op => 'between', value => [ 100, 2000 ] ),
		)
	],
	[
		'Starts with B or is a Ltd, and is not paid' => $F->all(
			$F->any(
				$F->new( column => 'customer', op => 'starts_with', value => 'B' ),
				$F->new( column => 'customer', op => 'matches',     value => qr/\bLtd\z/ ),
			),
			$F->not( $F->new( column => 'status', op => 'equals', value => 'p' ) ),
		)
	],
	[ 'More than 500 still owed' => sub ($row) { $row->{total} - $row->{paid} > 500 } ],
);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

my $table = Term::Fabulous::Widget::Table->new(
	id     => 'invoices',
	row_id => 'invoice',

	# The look: a block frame, and colors instead of grid lines.
	border       => 'Outer',
	column_lines => 'none',
	header_line  => 'none',
	stripe_color => '#1c2029',
	columns      => [
		{ key => 'invoice',  title => 'Invoice' },
		{ key => 'customer', title => 'Customer' },
		{ key => 'placed',   title => 'Placed', type    => 'date', mutator => date('%d %b %Y') },
		{ key => 'status',   title => 'Status', mutator => lookup( { o => 'open', p => 'paid', d => 'overdue' } ) },
		{ key => 'total',    title => 'Total',  type    => 'number', mutator => number( decimals => 2 ) },
		{ key => 'paid',     title => 'Paid',   type    => 'number', mutator => number( decimals => 2 ) },
	],
	rows => \@invoices,
);

my $help   = Term::Fabulous::Widget::Text->new( text => 'Keys 1 to 5 choose a filter, 0 shows all rows. Ctrl+C quits.', text_color => [ 150, 160, 180, 255 ] );
my $status = Term::Fabulous::Widget::Text->new( text => '',                                                             text_color => [ 229, 192, 123, 255 ] );
$root->add_child( $help, $table, $status );

sub choose_filter ($number) {
	if ( $number == 0 ) {
		$table->remove_filter('chosen');
		$status->text( sprintf '0: all rows (%d)', $table->row_count );
		return;
	}
	my ( $label, $filter ) = $choices[ $number - 1 ]->@*;
	$table->filter( chosen => $filter );
	$status->text( sprintf '%d: %s (%d of %d rows)', $number, $label, scalar $table->filtered_row_ids, $table->row_count );
	return;
}

# The table does not use the digit keys, so they bubble up to the root.
$root->on(
	KeyPress => sub ($event) {
		my $key = $event->key_name // return;
		return unless $key =~ /\A[0-5]\z/;
		choose_filter($key);
		return;
	}
);

my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );
choose_filter(0);
$ui->interaction->set_focused_widget($table);
$ui->run;
