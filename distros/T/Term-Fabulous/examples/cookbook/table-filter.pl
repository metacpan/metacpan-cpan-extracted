#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Table;
use Term::Fabulous::Widget::Table::Mutator qw(date number);
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::TextField;
use Clay::XS qw(sizing_grow sizing_fixed CLAY_TOP_TO_BOTTOM);

my @staff = (
	{ id => 1,  name => 'Ada Lovelace',      team => 'Core',     started => '2019-03-04', salary => 81000 },
	{ id => 2,  name => 'Grace Hopper',      team => 'Web',      started => '2021-11-15', salary => 92500 },
	{ id => 3,  name => 'Linus Torvalds',    team => 'Core',     started => '2017-06-01', salary => 90000 },
	{ id => 4,  name => 'Margaret Hamilton', team => 'Platform', started => '2016-02-22', salary => 99000 },
	{ id => 5,  name => 'Ken Thompson',      team => 'Core',     started => '2023-01-09', salary => 70000 },
	{ id => 6,  name => 'Barbara Liskov',    team => 'Platform', started => '2018-09-17', salary => 95500 },
	{ id => 7,  name => 'Dennis Ritchie',    team => 'Core',     started => '2020-05-11', salary => 78000 },
	{ id => 8,  name => 'Radia Perlman',     team => 'Network',  started => '2022-08-29', salary => 76000 },
	{ id => 9,  name => 'Tim Berners-Lee',   team => 'Web',      started => '2020-10-05', salary => 74500 },
	{ id => 10, name => 'Frances Allen',     team => 'Platform', started => '2024-02-12', salary => 68000 },
	{ id => 11, name => 'Hedy Lamarr',       team => 'Network',  started => '2019-12-02', salary => 88000 },
	{ id => 12, name => 'Katherine Johnson', team => 'Research', started => '2021-03-08', salary => 83000 },
);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

my $search = Term::Fabulous::Widget::TextField->new(
	id          => 'search',
	placeholder => 'Search all columns',
	layout      => { sizing => { width => sizing_fixed(30) } },
);

my $table = Term::Fabulous::Widget::Table->new(
	id         => 'staff',
	row_id     => 'id',
	filter_row => 1,
	sort       => ['name'],
	layout     => { sizing => { width => sizing_grow() } },

	# The look: a block frame, and colors instead of grid lines.
	border       => 'Outer',
	column_lines => 'none',
	header_line  => 'none',
	stripe_color => '#1c2029',
	columns      => [
		{ key => 'name',    title => 'Name',    width => 'grow' },
		{ key => 'team',    title => 'Team',    width => 'fixed(14)' },
		{ key => 'started', title => 'Started', width => 'fixed(16)', type => 'date',   mutator => date('%d %b %Y') },
		{ key => 'salary',  title => 'Salary',  width => 'fixed(14)', type => 'number', mutator => number( decimals => 0 ) },
	],
	rows => \@staff,
);

my $status = Term::Fabulous::Widget::Text->new( text => '',                                                                  text_color => [ 229, 192, 123, 255 ] );
my $help   = Term::Fabulous::Widget::Text->new( text => 'Tab: next field. Try "core", ">=80000", ">=2020" or "2019..2021".', text_color => [ 150, 160, 180, 255 ] );
$root->add_child( $search, $table, $status, $help );

# The count of the rows that pass, or why a filter field is not used.
sub show_count () {
	foreach my $key ( $table->column_keys ) {
		my $error = $table->filter_error($key) // next;
		$status->text( sprintf '%s: %s', $table->column($key)->title, $error );
		return;
	}
	$status->text( sprintf '%d of %d rows', scalar $table->filtered_row_ids, $table->row_count );
	return;
}

$search->on(
	Change => sub ($event) {
		$table->search( $event->value );
		show_count();
		return;
	}
);

$table->on(
	FilterChange => sub ($event) {
		show_count();
		return;
	}
);

my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );
show_count();
$ui->interaction->set_focused_widget($search);
$ui->run;
