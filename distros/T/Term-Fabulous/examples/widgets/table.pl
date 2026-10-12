#!/usr/bin/env perl

# Term::Fabulous::Widget::Table: a list of staff with a filter row,
# multiple selection, sorting, formatted dates and numbers, striped rows
# and pages. Up and Down move the cursor, Space selects a row, Shift with
# an arrow key selects a range, Ctrl+A selects all. Click a column title
# (or press Up on the first row, then Enter) to sort. Type into the
# fields below the titles to filter: "web", ">80000", ">=2021". Ctrl+PageDown
# and Ctrl+PageUp turn the pages. Ctrl+C quits.
#
#     perl examples/widgets/table.pl

use v5.32;
use warnings;
use strict;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../../lib/";

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Table;
use Term::Fabulous::Widget::Table::Mutator qw(boolean date number);
use Term::Fabulous::Widget::Text;

use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my @STAFF = (
	[ 'Ada Lovelace',      'Core',     'Engineer',  '2019-03-04', 81000,  1 ],
	[ 'Grace Hopper',      'Web',      'Lead',      '2021-11-15', 92500,  0 ],
	[ 'Linus Torvalds',    'Core',     'Engineer',  '2017-06-01', 90000,  1 ],
	[ 'Margaret Hamilton', 'Platform', 'Architect', '2016-02-22', 99000,  0 ],
	[ 'Ken Thompson',      'Core',     'Engineer',  '2023-01-09', 70000,  1 ],
	[ 'Barbara Liskov',    'Platform', 'Lead',      '2018-09-17', 95500,  0 ],
	[ 'Dennis Ritchie',    'Core',     'Engineer',  '2020-05-11', 78000,  0 ],
	[ 'Radia Perlman',     'Network',  'Engineer',  '2022-08-29', 76000,  1 ],
	[ 'Tim Berners-Lee',   'Web',      'Engineer',  '2020-10-05', 74500,  1 ],
	[ 'Frances Allen',     'Platform', 'Engineer',  '2024-02-12', 68000,  0 ],
	[ 'John McCarthy',     'Research', 'Fellow',    '2015-04-20', 105000, 0 ],
	[ 'Hedy Lamarr',       'Network',  'Lead',      '2019-12-02', 88000,  1 ],
	[ 'Edsger Dijkstra',   'Research', 'Fellow',    '2016-07-18', 101000, 0 ],
	[ 'Katherine Johnson', 'Research', 'Engineer',  '2021-03-08', 83000,  1 ],
);

my @rows;
foreach my $person (@STAFF) {
	my %row = ( id => scalar @rows + 1 );
	@row{qw(name team role started salary remote)} = @$person;
	push @rows, \%row;
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
	id         => 'staff',
	row_id     => 'id',
	selection  => 'multiple',
	filter_row => 1,
	page_size  => 10,
	page_sizes => [ 5, 10, 25 ],
	sort       => [ [ started => 'desc' ] ],

	# The look: a block frame, and colors instead of grid lines.
	border       => 'Outer',
	column_lines => 'none',
	header_line  => 'none',
	stripe_color => [ 26, 31, 41, 255 ],
	columns      => [
		{ key => 'name',    title => 'Name' },
		{ key => 'team',    title => 'Team' },
		{ key => 'role',    title => 'Role' },
		{ key => 'started', title => 'Started', type  => 'date',   mutator => date('%d %b %Y') },
		{ key => 'salary',  title => 'Salary',  type  => 'number', mutator => number( decimals => 0 ) },
		{ key => 'remote',  title => 'Remote',  align => 'center', mutator => boolean( 'yes', '' ), filterable => 0 },
	],
	rows => \@rows,
);

my $status = Term::Fabulous::Widget::Text->new( text => 'Nothing selected', text_color => [ 150, 160, 180, 255 ] );
$table->on(
	SelectionChange => sub ($event) {
		my @names = map { $_->{name} } $table->selected_rows;
		$status->text( @names ? 'Selected: ' . join( ', ', @names ) : 'Nothing selected' );
		return;
	}
);

$root->add_child( $table, $status );

my $ui = Term::Fabulous->new( width => 80, height => 24, root => $root );
$ui->interaction->set_focused_widget($table);
$ui->run;
