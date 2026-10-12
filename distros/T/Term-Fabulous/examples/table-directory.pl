#!/usr/bin/env perl

# A staff directory built on Term::Fabulous::Widget::Table: a search box,
# rows grouped by team, multiple selection, formatted values, styles that
# follow the data, pages, a details panel that follows the cursor, and a
# column chooser.
#
#     perl examples/table-directory.pl
#
# Keys: Tab moves between the search box, the table and the pager. In the
# table: Up/Down move, Space selects, Shift+Up/Down select a range, Ctrl+A
# selects all, Left/Right close and open groups, Enter on a group header
# toggles it. Up on the first line reaches the column titles: Left/Right
# pick a column, Enter sorts by it, c opens the column chooser. F2 opens
# the column chooser too, F3 switches the grouping on and off, Escape or
# Ctrl+C quits.

use v5.32;
use warnings;
use strict;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../lib/";

use Term::Fabulous;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Table;
use Term::Fabulous::Widget::Table::Mutator qw(boolean date lookup number);
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::TextField;

use Clay::XS qw(sizing_fixed sizing_grow CLAY_LEFT_TO_RIGHT CLAY_TOP_TO_BOTTOM);

my $MUTED = [ 140, 150, 170, 255 ];
my $TEXT  = [ 220, 223, 228, 255 ];

# --- The data: fixed, so every run shows the same ---------------------------

my @FIRST   = qw(Ada Grace Linus Margaret Ken Barbara Dennis Radia Tim Frances John Hedy Edsger Katherine Alan Joan Donald Sophie Guido Anita);
my @LAST    = qw(Lovelace Hopper Torvalds Hamilton Thompson Liskov Ritchie Perlman Berners-Lee Allen McCarthy Lamarr Dijkstra Johnson Turing Clarke Knuth Wilson Rossum Borg);
my @TEAMS   = qw(Core Web Platform Research Network);
my @ROLES   = qw(Engineer Engineer Engineer Lead Architect Fellow);
my %OFFICE  = ( BER => 'Berlin', LON => 'London', NYC => 'New York', REM => 'Remote' );
my @OFFICES = sort keys %OFFICE;

my @people;
foreach my $index ( 0 .. $#FIRST ) {
	push @people, {
		id       => sprintf( 'E%03d', 101 + $index ),
		name     => "$FIRST[$index] $LAST[$index]",
		team     => $TEAMS[ $index * 7 % @TEAMS ],
		role     => $ROLES[ $index * 5 % @ROLES ],
		office   => $OFFICES[ $index * 3 % @OFFICES ],
		started  => sprintf( '%d-%02d-%02d', 2014 + $index * 3 % 11, 1 + $index * 5 % 12, 1 + $index * 11 % 28 ),
		salary   => 64000 + ( $index * 7919 ) % 46000,
		on_leave => $index % 9 == 4 ? 1 : 0,
		email    => lc( $FIRST[$index] ) . '@example.com',
	};
}

# --- The widgets ---------------------------------------------------------------

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

sub text ( $string, $color = $TEXT, %more ) {
	return Term::Fabulous::Widget::Text->new( text => $string, text_color => $color, %more );
}

my $search = Term::Fabulous::Widget::TextField->new(
	id                => 'search',
	placeholder       => 'Search all columns',
	preferred_columns => 30,
);
my $top = Term::Fabulous::Widget::Box->new( layout => { child_gap => 2 } );
$top->add_child( text( 'Staff directory', [ 97, 175, 239, 255 ], bold => 1 ), $search, text( 'F2 columns  F3 grouping  Esc quit', $MUTED ) );

my $table = Term::Fabulous::Widget::Table->new(
	id         => 'staff',
	row_id     => 'id',
	selection  => 'multiple',
	group_by   => 'team',
	sort       => ['name'],
	page_size  => 15,
	page_sizes => [ 10, 15, 30 ],
	layout     => { sizing => { width => sizing_grow(), height => sizing_grow() } },

	# The look: a block frame, and colors instead of grid lines.
	border       => 'Outer',
	column_lines => 'none',
	header_line  => 'none',
	stripe_color => [ 26, 31, 41, 255 ],
	columns      => [
		{ key => 'name',    title => 'Name', width => 'grow' },
		{ key => 'team',    title => 'Team' },
		{ key => 'role',    title => 'Role' },
		{ key => 'office',  title => 'Office',  mutator => lookup( \%OFFICE ) },
		{ key => 'started', title => 'Started', type    => 'date', mutator => date('%b %Y') },
		{
			key        => 'salary', title => 'Salary', type => 'number', mutator => number( decimals => 0 ),
			cell_style => sub ($cell) { $cell->{value} >= 100000 ? { text_color => [ 229, 192, 123, 255 ] } : undef }
		},
		{ key => 'id',       title => 'Id',       visible => 0 },
		{ key => 'email',    title => 'E-mail',   visible => 0 },
		{ key => 'on_leave', title => 'On leave', visible => 0, mutator => boolean( 'yes', '' ) },
	],
	row_style   => sub ( $row, $id ) { $row->{on_leave} ? { text_color => $MUTED, italic => 1 } : undef },
	group_label => sub ($group) {
		my $payroll = 0;
		$payroll += $group->{table}->value( $_, 'salary' ) foreach @{ $group->{ids} };
		return sprintf '%s  -  %d people, payroll %s', $group->{display}, $group->{count}, number( decimals => 0 )->( $payroll, {} );
	},
	rows => \@people,
);

my $details = Term::Fabulous::Widget::Box->new(
	bordered     => 1,
	border_style => Term::Fabulous::Enum::BorderStyle->Outer,
	border_color => [ 88, 96, 112, 255 ],
	layout       => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_fixed(28), height => sizing_grow() },
		padding          => { left  => 1,                right  => 1 },
	},
);
my $details_text = text('');
$details->add_child( text( 'Details', [ 97, 175, 239, 255 ], bold => 1 ), $details_text );

my $middle = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_LEFT_TO_RIGHT, sizing => { width => sizing_grow(), height => sizing_grow() }, child_gap => 2 } );
$middle->add_child( $table, $details );

my $status = text( '', $MUTED );
$root->add_child( $top, $middle, $status );

# --- Behavior ------------------------------------------------------------------

sub show_details () {
	my $id = $table->cursor;
	unless ( defined $id ) {
		my $path = $table->cursor_group;
		$details_text->text( defined $path ? "Team $path->[0]\n\nEnter or Space opens\nand closes the group." : '' );
		return;
	}
	my $person = $table->row($id);
	$details_text->text(
		join "\n",
		$person->{name}, '',
		"Id      $person->{id}",
		"Team    $person->{team}",
		"Role    $person->{role}",
		"Office  " . $table->display_value( $id, 'office' ),
		"Since   " . $table->display_value( $id, 'started' ),
		"Salary  " . $table->display_value( $id, 'salary' ),
		"E-mail  $person->{email}",
		$person->{on_leave} ? "\nOn leave" : ()
	);
	return;
}

sub show_status () {
	my @selected = $table->selected_ids;
	$status->text(
		sprintf '%d of %d people shown, %d selected%s',
		scalar $table->filtered_row_ids, $table->row_count, scalar @selected,
		@selected ? ': ' . join( ', ', map { $table->row($_)->{name} } @selected ) : ''
	);
	return;
}

$search->on( Change => sub ($event) { $table->search( $event->value ); show_status(); show_details(); return } );
$table->on( CursorMove      => sub ($event) { show_details();                                                                               return } );
$table->on( SelectionChange => sub ($event) { show_status();                                                                                return } );
$table->on( RowActivate     => sub ($event) { $details_text->text( $details_text->text . "\n\n(Enter: open " . $event->row->{name} . ')' ); return } );

my $ui = Term::Fabulous->new( root => $root, width => 120, height => 32 );

# Keys the table and the search box do not use bubble up to the root.
$root->on(
	KeyPress => sub ($event) {
		my $key = $event->key_name // return;
		if    ( $key eq 'F2' )     { $table->open_column_chooser }
		elsif ( $key eq 'F3' )     { $table->group_by ? $table->ungroup : $table->group_by('team') }
		elsif ( $key eq 'Escape' ) { $ui->loop->stop }
		return;
	}
);

show_status();
show_details();
$ui->interaction->set_focused_widget($table);
$ui->run;
