#!/usr/bin/env perl

# A file browser built on Term::Fabulous::Widget::Table: nested rows (a
# tree) with sizes, dates and kinds, a filter row that keeps the folders
# of every match, single selection, and a folder whose contents are only
# loaded when it is opened.
#
#     perl examples/table-files.pl
#
# Keys: Up/Down move (the selection follows), Right/+ open a folder,
# Left/- close it or go to the parent folder, Enter "opens" a file. Tab
# reaches the filter fields: type part of a name ("util"), a size (">10000")
# or a date ("2026-05"); Enter or Down returns to the rows. e opens every
# folder, c closes every folder, Escape or Ctrl+C quits.

use v5.32;
use warnings;
use strict;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../lib/";

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Table;
use Term::Fabulous::Widget::Table::Mutator qw(bytes datetime lookup);
use Term::Fabulous::Widget::Text;

use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my $MUTED = [ 140, 150, 170, 255 ];

# --- The data: a fixed tree, so every run shows the same ---------------------

my $DAY = 86400;
my $NOW = 1780306860;    # 2026-06-01 09:41 UTC

# file(name, size, days ago) and folder(name, days ago, children)
sub file ( $name, $size, $age ) {
	return { name => $name, kind => ( $name =~ /\.(\w+)\z/ ? $1 : 'file' ), size => $size, modified => $NOW - $age * $DAY };
}

sub folder ( $name, $age, @children ) {
	return { name => $name, kind => 'dir', modified => $NOW - $age * $DAY, children => \@children };
}

# Folder paths are the row ids; every row gets its path from its parents.
sub with_paths ( $parent, @rows ) {
	foreach my $row (@rows) {
		$row->{path} = "$parent/$row->{name}";
		with_paths( $row->{path}, @{ $row->{children} } ) if $row->{children};
	}
	return @rows;
}

# A folder's size is the sum of its contents.
sub total ($row) {
	return $row->{size} //= 0 unless $row->{children};
	my $sum = 0;
	$sum += total($_) foreach @{ $row->{children} };
	return $row->{size} = $sum;
}

my @tree = with_paths(
	'',
	folder(
		'project', 1,
		folder( 'lib',    2,  file( 'App.pm',      18_420, 2 ),  folder( 'App', 3, file( 'Config.pm', 6_210, 3 ), file( 'Util.pm', 9_877, 12 ), file( 'Server.pm', 24_003, 5 ) ) ),
		folder( 't',      4,  file( 'basic.t',     2_310,  4 ),  file( 'config.t', 4_512,   30 ), file( 'util.t', 3_904, 12 ) ),
		folder( 'docs',   40, file( 'manual.pod',  88_115, 40 ), file( 'logo.png', 245_760, 300 ) ),
		folder( 'vendor', 60, file( 'placeholder', 0,      60 ) ),    # loaded when opened
		file( 'README.md',   5_120, 9 ),
		file( 'Makefile.PL', 1_380, 90 ),
		file( 'Changes',     3_002, 1 ),
	),
);
total($_) foreach @tree;

# --- The widgets ---------------------------------------------------------------

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

my $table = Term::Fabulous::Widget::Table->new(
	id           => 'files',
	row_id       => 'path',
	children_key => 'children',
	selection    => 'single',
	filter_row   => 1,
	sort         => [ 'kind', 'name' ],

	# The look: a block frame, and colors instead of grid lines.
	border       => 'Outer',
	column_lines => 'none',
	header_line  => 'none',
	stripe_color => '#1c2029',
	columns      => [
		{ key => 'name',     title => 'Name',     width => 'fit(24)', compare => 'natural' },
		{ key => 'size',     title => 'Size',     type  => 'number',  mutator => bytes() },
		{ key => 'modified', title => 'Modified', type  => 'date',    mutator => datetime( '%Y-%m-%d %H:%M', utc => 1 ) },
		{
			key     => 'kind', title => 'Kind',
			mutator => lookup( { dir => 'folder', pm => 'Perl module', t => 'test', pod => 'documentation', png => 'image', md => 'text', PL => 'Perl script' }, default => 'file' ),
			compare => sub ( $left, $right, @rows ) { ( $left eq 'dir' ? 0 : 1 ) <=> ( $right eq 'dir' ? 0 : 1 ) }
		},
	],
	row_style => sub ( $row, $id ) { $row->{kind} eq 'dir' ? { text_color => [ 97, 175, 239, 255 ], bold => 1 } : undef },
	rows      => \@tree,
);
$table->expand( '/project', '/project/lib' );

my $status = Term::Fabulous::Widget::Text->new( text => '', text_color => $MUTED );
$root->add_child(
	Term::Fabulous::Widget::Text->new( text => 'e opens all folders, c closes them, Esc quits', text_color => $MUTED ),
	$table, $status,
);

# --- Behavior ------------------------------------------------------------------

sub show_status ( $note = '' ) {
	my $id  = $table->cursor // return;
	my $row = $table->row($id);
	$status->text( sprintf '%s  %s%s', $id, $table->display_value( $id, 'size' ), length $note ? "  - $note" : '' );
	return;
}

$table->on( CursorMove  => sub ($event) { show_status();                                                                       return } );
$table->on( RowActivate => sub ($event) { show_status( $event->row->{kind} eq 'dir' ? 'a folder: Right opens it' : 'opened' ); return } );

# The vendor folder holds a placeholder until it is opened for the first time.
$table->on(
	Expand => sub ($event) {
		my $id = $event->row_id // return;
		return unless $table->has_row("$id/placeholder");
		$table->remove_row("$id/placeholder");
		my @files = with_paths( $id, file( 'JSON-PP.tar.gz', 61_440, 60 ), file( 'Try-Tiny.tar.gz', 14_336, 60 ) );
		$table->add_rows( \@files, parent => $id );
		my $size = 0;
		$size += $_->{size} foreach @files;
		$table->set_value( $id, size => $size );
		show_status('loaded');
		return;
	}
);

my $ui = Term::Fabulous->new( root => $root, width => 100, height => 30 );

# Keys the table does not use bubble up to the root.
$root->on(
	KeyPress => sub ($event) {
		my $key = $event->key_name // return;
		if    ( $key eq 'e' )      { $table->expand_all }
		elsif ( $key eq 'c' )      { $table->collapse_all }
		elsif ( $key eq 'Escape' ) { $ui->loop->stop }
		return;
	}
);

show_status();
$ui->interaction->set_focused_widget($table);
$ui->run;
