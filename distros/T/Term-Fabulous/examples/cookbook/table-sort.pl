#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Table;
use Term::Fabulous::Widget::Text;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my @tickets = (
	{ ticket => 'T-9',   title => 'Crash on empty config',    priority => 'high',   version => '2.10.1', opened => '2026-05-12', note => 'add a test' },
	{ ticket => 'T-10',  title => 'Typo in the help text',    priority => 'low',    version => '2.9',    opened => '2026-05-20', note => '' },
	{ ticket => 'T-2',   title => 'Slow start, 1000 rows',    priority => 'normal', version => '2.10',   opened => '2026-04-02', note => 'profile' },
	{ ticket => 'T-11',  title => 'Dark theme for the pager', priority => 'normal', version => '2.9.3',  opened => '2026-05-28', note => '' },
	{ ticket => 'T-101', title => 'Wrong date in reports',    priority => 'high',   version => '2.9.12', opened => '2026-05-30', note => 'customer' },
	{ ticket => 'T-7',   title => 'Mouse wheel too fast',     priority => 'low',    version => '2.10',   opened => '2026-03-15', note => '' },
);

# The order of the priorities: a custom comparison gets two raw values
# (and copies of the two rows) and returns a number like <=> does.
my %RANK = ( high => 1, normal => 2, low => 3 );

sub by_priority ( $left, $right, $left_row, $right_row ) {
	return ( $RANK{ $left // '' } // 9 ) <=> ( $RANK{ $right // '' } // 9 );
}

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

my $table = Term::Fabulous::Widget::Table->new(
	id     => 'tickets',
	row_id => 'ticket',
	sort   => [ 'priority', [ opened => 'desc' ] ],    # highest priority first, newest first within each
		# The look: a block frame, and colors instead of grid lines.
	border       => 'Outer',
	column_lines => 'none',
	header_line  => 'none',
	stripe_color => '#1c2029',
	columns      => [
		{ key => 'ticket',   title => 'Ticket', compare => 'natural' },    # T-2 before T-10
		{ key => 'title',    title => 'Title' },
		{ key => 'priority', title => 'Priority', compare  => \&by_priority },
		{ key => 'version',  title => 'Version',  compare  => 'natural' },    # 2.9.3 before 2.10
		{ key => 'opened',   title => 'Opened',   type     => 'date' },
		{ key => 'note',     title => 'Note',     sortable => 0 },
	],
	rows => \@tickets,
);

sub describe_sort ($spec) {
	return 'Not sorted: the rows are in data order.' unless @$spec;
	return 'Sorted by ' . join ', then ', map { "$_->[0] ($_->[1])" } @$spec;
}

my $help   = Term::Fabulous::Widget::Text->new( text => 'Click a title to sort, Ctrl+click adds it. Keys: Up into the titles, then Enter or Space.', text_color => [ 150, 160, 180, 255 ] );
my $status = Term::Fabulous::Widget::Text->new( text => describe_sort( $table->sort_spec ),                                                          text_color => [ 229, 192, 123, 255 ] );
$root->add_child( $help, $table, $status );

$table->on(
	SortChange => sub ($event) {
		$status->text( describe_sort( $event->sort ) );
		return;
	}
);

my $ui = Term::Fabulous->new( root => $root, width => 96, height => 20 );
$ui->interaction->set_focused_widget($table);
$ui->run;
