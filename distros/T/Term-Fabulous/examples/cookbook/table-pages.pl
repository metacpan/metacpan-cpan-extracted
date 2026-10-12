#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Table;
use Term::Fabulous::Widget::Table::Mutator qw(datetime number);
use Term::Fabulous::Widget::Text;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

# 300 orders, made up from fixed lists, so every run shows the same data.
my @customers = ( 'Acme Corp', 'Globex', 'Initech', 'Umbrella', 'Hooli', 'Stark Industries', 'Wayne Enterprises' );
my @states    = qw(open paid shipped);
my $first_day = 1767225600;    # 2026-01-01 00:00 UTC

my @orders = map {
	{
		number   => 10_000 + $_,
		placed   => $first_day + $_ * 41_113,
		customer => $customers[ $_ * 5 % @customers ],
		state    => $states[ $_ * 7 % @states ],
		total    => ( $_ * 7_919 % 90_000 ) / 100 + 10,
	}
} 1 .. 300;

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

my $table = Term::Fabulous::Widget::Table->new(
	id         => 'orders',
	row_id     => 'number',
	page_size  => 10,
	page_sizes => [ 10, 20, 50 ],

	# The look: a block frame, and colors instead of grid lines.
	border       => 'Outer',
	column_lines => 'none',
	header_line  => 'none',
	stripe_color => '#1c2029',
	columns      => [
		{ key => 'number',   title => 'Order',  type => 'number' },
		{ key => 'placed',   title => 'Placed', type => 'date', mutator => datetime( '%d %b %Y %H:%M', utc => 1 ) },
		{ key => 'customer', title => 'Customer' },
		{ key => 'state',    title => 'State' },
		{ key => 'total',    title => 'Total', type => 'number', mutator => number( decimals => 2, prefix => '$' ) },
	],
	rows => \@orders,
);

my $status = Term::Fabulous::Widget::Text->new( text => '', text_color => [ 150, 160, 180, 255 ] );
$root->add_child( $table, $status );

sub show_page ( $page, $page_size ) {
	my @shown = $table->page_row_ids;
	$status->text( sprintf 'Page %d of %d, %d per page: orders %d to %d', $page, $table->page_count, $page_size, $shown[0], $shown[-1] );
	return;
}

# The pager, Ctrl+PageDown and Ctrl+PageUp fire PageChange, and so does a
# new size from the pager's list of page sizes.
$table->on( PageChange => sub ($event) { show_page( $event->page, $event->page_size ); return } );

show_page( $table->page, $table->page_size );
my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );
$ui->interaction->set_focused_widget($table);
$ui->run;
