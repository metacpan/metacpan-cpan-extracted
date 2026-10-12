#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Table;
use Term::Fabulous::Widget::Table::Mutator qw(bytes datetime);
use Term::Fabulous::Widget::Text;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

sub file ( $path, $size, $modified ) {
	my ($name) = $path =~ m{([^/]+)\z};
	return { path => $path, name => $name, size => $size, modified => $modified };
}

sub folder ( $path, $modified, @children ) {
	my ($name) = $path =~ m{([^/]+)\z};
	return { path => $path, name => "$name/", modified => $modified, children => \@children };
}

# A folder whose entries are read only when the user opens it: its one
# child is a placeholder, which the Expand listener below replaces.
sub folder_to_load ( $path, $modified ) {
	return folder( $path, $modified, { path => "$path/...", name => 'loading...' } );
}

# What a real program would read from the disk with opendir and stat.
my %ON_DISK = (
	'/project/releases' => [
		file( '/project/releases/app-1.0.tar.gz', 48_211,  1767225600 ),
		file( '/project/releases/app-1.1.tar.gz', 51_876,  1772323200 ),
		file( '/project/releases/app-2.0.tar.gz', 204_413, 1779753600 ),
	],
);

my $table = Term::Fabulous::Widget::Table->new(
	id           => 'files',
	row_id       => 'path',
	children_key => 'children',
	tree_column  => 'name',

	# The look: a block frame, and colors instead of grid lines.
	border       => 'Outer',
	column_lines => 'none',
	header_line  => 'none',
	stripe_color => '#1c2029',
	columns      => [
		{ key => 'name',     title => 'Name' },
		{ key => 'size',     title => 'Size',     type => 'number', mutator => bytes() },
		{ key => 'modified', title => 'Modified', type => 'date',   mutator => datetime( '%Y-%m-%d %H:%M', utc => 1 ) },
	],
	rows => [
		folder(
			'/project', 1780310460,
			folder(
				'/project/src', 1780307100,
				file( '/project/src/main.pl', 2_841, 1780307100 ),
				folder(
					'/project/src/lib', 1780220400,
					file( '/project/src/lib/App.pm',  18_506, 1780220400 ),
					file( '/project/src/lib/Util.pm', 4_402,  1779874800 ),
				),
			),
			folder( '/project/t', 1780138200, file( '/project/t/basic.t', 1_377, 1780138200 ), file( '/project/t/util.t', 2_019, 1779960000 ) ),
			folder_to_load( '/project/releases', 1779753600 ),
			file( '/project/README.md',   6_310, 1780048800 ),
			file( '/project/Makefile.PL', 912,   1777996800 ),
		),
	],
);
$table->expand( '/project', '/project/src' );

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);
my $help   = Term::Fabulous::Widget::Text->new( text => 'Right opens a folder, Left closes it. Click a marker to toggle.', text_color => [ 150, 160, 180, 255 ] );
my $status = Term::Fabulous::Widget::Text->new( text => 'Open releases/ to load its files.',                               text_color => [ 229, 192, 123, 255 ] );
$root->add_child( $help, $table, $status );

$table->on(
	Expand => sub ($event) {
		my $path = $event->row_id // return;
		if ( $table->has_row("$path/...") ) {
			$table->remove_row("$path/...");
			$table->add_rows( $ON_DISK{$path} // [], parent => $path );
		}
		$status->text( sprintf 'Opened %s: %d entries', $path, scalar $table->children_of($path) );
		return;
	}
);
$table->on(
	Collapse => sub ($event) {
		my $path = $event->row_id // return;
		$status->text("Closed $path");
		return;
	}
);

my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );
$ui->interaction->set_focused_widget($table);
$ui->run;
