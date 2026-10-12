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
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my @staff = (
	[ 'Ada Lovelace',   'Core',     'Engineer',  'London',    'ada@example.com',     '555-0101', '2019-03-04', 81_000 ],
	[ 'Grace Hopper',   'Web',      'Lead',      'New York',  'grace@example.com',   '555-0102', '2021-11-15', 92_500 ],
	[ 'Linus Torvalds', 'Core',     'Engineer',  'Portland',  'linus@example.com',   '555-0103', '2017-06-01', 90_000 ],
	[ 'Radia Perlman',  'Network',  'Engineer',  'Boston',    'radia@example.com',   '555-0104', '2022-08-29', 76_000 ],
	[ 'Barbara Liskov', 'Platform', 'Architect', 'Cambridge', 'barbara@example.com', '555-0105', '2018-09-17', 95_500 ],
	[ 'Ken Thompson',   'Core',     'Engineer',  'Berkeley',  'ken@example.com',     '555-0106', '2023-01-09', 70_000 ],
);
my @keys = qw(name team role city email phone started salary);
my @rows = map {
	my %row;
	@row{@keys} = @$_;
	\%row;
} @staff;

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

my $table = Term::Fabulous::Widget::Table->new(
	id     => 'staff',
	row_id => 'email',

	# The look: a block frame, and colors instead of grid lines.
	border       => 'Outer',
	column_lines => 'none',
	header_line  => 'none',
	stripe_color => '#1c2029',
	columns      => [
		{ key => 'name',    title => 'Name' },
		{ key => 'team',    title => 'Team' },
		{ key => 'role',    title => 'Role' },
		{ key => 'city',    title => 'City' },
		{ key => 'email',   title => 'E-mail',  visible => 0 },
		{ key => 'phone',   title => 'Phone',   visible => 0 },
		{ key => 'started', title => 'Started', type    => 'date',   mutator => date('%b %Y') },
		{ key => 'salary',  title => 'Salary',  type    => 'number', mutator => number( decimals => 0 ), visible => 0 },
	],
	rows => \@rows,
);

my $status = Term::Fabulous::Widget::Text->new( text => '', text_color => [ 150, 160, 180, 255 ] );
my $help   = Term::Fabulous::Widget::Text->new(
	text       => 'F2 or c in the header: choose columns   F3: name and contact   F4: all   F5: no contact',
	text_color => [ 110, 120, 140, 255 ],
);
$root->add_child( $table, $status, $help );

# A real program would store the list, for example in a settings file.
sub show_columns_to_save (@visible) {
	$status->text( 'Would save: ' . join ', ', @visible );
	return;
}

# The user's changes in the column chooser.
$table->on( ColumnsChange => sub ($event) { show_columns_to_save( @{ $event->visible } ); return } );

# Changes from Perl fire no ColumnsChange.
my %action_of_key = (
	F2 => sub () { $table->open_column_chooser },
	F3 => sub () { $table->set_visible_columns(qw(name email phone)) },
	F4 => sub () { $table->show_columns( $table->column_keys ) },
	F5 => sub () { $table->hide_columns(qw(email phone)) },
);
$root->on(
	KeyPress => sub ($event) {
		my $action = $action_of_key{ $event->key_name // '' } // return;
		$action->();
		show_columns_to_save( $table->visible_columns );
		return;
	}
);

show_columns_to_save( $table->visible_columns );
my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );
$ui->interaction->set_focused_widget($table);
$ui->run;
