#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Button;
use Term::Fabulous::Widget::Checkbox;
use Term::Fabulous::Widget::Table;
use Term::Fabulous::Widget::Table::Mutator qw(date);
use Term::Fabulous::Widget::Text;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my @tasks = (
	{ id => 1, done => 1, task => 'Order new monitors',  due => '2026-06-02', hours => 1, note => 'Two 27 inch' },
	{ id => 2, done => 0, task => 'Review pull request', due => '2026-06-03', hours => 2, note => '' },
	{ id => 3, done => 0, task => 'Write release notes', due => '2026-06-05', hours => 3, note => 'Ask Grace' },
	{ id => 4, done => 1, task => 'Book meeting room',   due => '2026-06-01', hours => 1, note => '' },
	{ id => 5, done => 0, task => 'Update test server',  due => '2026-06-08', hours => 4, note => 'After 18:00' },
);
my $next_id = @tasks + 1;

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

# A check box per row. It writes its state back into the row data;
# update_cell keeps the same check box when that data changes.
my $done_column = {
	key        => 'done',
	title      => 'Done',
	filterable => 0,
	cell       => sub ($cell) {
		my ( $table, $id ) = @{$cell}{qw(table id)};
		my $box = Term::Fabulous::Widget::Checkbox->new( checked => $cell->{value} ? 1 : 0 );
		$box->on( Change => sub ($event) { $table->set_value( $id, done => $event->value ? 1 : 0 ); show_status(); return } );
		return $box;
	},
	update_cell => sub ( $box, $cell ) { $box->checked( $cell->{value} ? 1 : 0 ) },
};

# A button per row that removes its own row. The button goes with the
# row; the table then takes the keyboard focus.
my $delete_column = {
	key        => 'delete',
	title      => '',
	sortable   => 0,
	filterable => 0,
	cell       => sub ($cell) {
		my ( $table, $id ) = @{$cell}{qw(table id)};
		my $button = Term::Fabulous::Widget::Button->new( background_color => [ 90, 40, 45, 255 ], layout => { padding => { left => 1, right => 1 } } );
		$button->add_child( Term::Fabulous::Widget::Text->new( text => 'Delete', text_color => [ 255, 255, 255, 255 ] ) );
		$button->on(
			Activate => sub ($event) {
				$table->remove_row($id);
				show_status();
				return;
			}
		);
		return $button;
	},
};

my $note_column = { key => 'note', title => 'Note' };

my $table = Term::Fabulous::Widget::Table->new(
	id        => 'tasks',
	row_id    => 'id',
	selection => 'multiple',

	# The look: a block frame, and colors instead of grid lines.
	border       => 'Outer',
	column_lines => 'none',
	header_line  => 'none',
	stripe_color => '#1c2029',
	columns      => [
		$done_column,
		{ key => 'task',  title => 'Task' },
		{ key => 'due',   title => 'Due',   type => 'date', mutator => date('%a %d %b') },
		{ key => 'hours', title => 'Hours', type => 'number' },
		$delete_column,
	],
	rows => \@tasks,
);

my $status = Term::Fabulous::Widget::Text->new( text => '', text_color => [ 150, 160, 180, 255 ] );
my $help   = Term::Fabulous::Widget::Text->new(
	text       => 'a: add a task   Delete: remove selected tasks   h: one more hour   n: notes',
	text_color => [ 110, 120, 140, 255 ],
);
$root->add_child( $table, $status, $help );

# Changes from Perl fire no events, so the program updates the status
# line itself after each change it makes.
sub show_status () {
	my @ids      = $table->row_ids;
	my @selected = $table->selected_ids;
	my $done     = grep { $table->value( $_, 'done' ) } @ids;
	$status->text( sprintf '%d of %d tasks done, %d selected', $done, scalar @ids, scalar @selected );
	return;
}

my %action_of_key = (
	a => sub () {
		$table->add_row( { id => $next_id, done => 0, task => "New task $next_id", due => '2026-06-10', hours => 1, note => '' } );
		$next_id++;
	},
	Delete => sub () {
		my @selected = $table->selected_ids;
		$table->remove_rows(@selected) if @selected;
	},
	h => sub () {
		my $id = $table->cursor // return;
		$table->update_row( $id, { hours => $table->value( $id, 'hours' ) + 1 } );
	},
	n => sub () {
		if ( grep { $_ eq 'note' } $table->column_keys ) {
			$table->remove_column('note');
			return;
		}
		$table->add_column( $note_column, index => 2 );
	},
);

# The table does not use these keys, so they bubble up to the root.
$root->on(
	KeyPress => sub ($event) {
		my $action = $action_of_key{ $event->key_name // '' } // return;
		$action->();
		show_status();
		return;
	}
);
$table->on( SelectionChange => sub ($event) { show_status(); return } );

show_status();
my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );
$ui->interaction->set_focused_widget($table);
$ui->run;
