#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Table;
use Term::Fabulous::Widget::Table::Mutator qw(datetime number percent bytes duration boolean lookup truncate);
use Term::Fabulous::Widget::Text;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

# Raw data, as a backup tool would report it: epoch seconds, byte counts,
# seconds, fractions, flags and short state codes.
my @backups = (
	{ id => 1, job => 'home directories', state => 'ok',   started => 1780266600, seconds => 3725, size => 48_318_382_080,  files => 182_340, changed => 0.153,  encrypted => 1 },
	{ id => 2, job => 'mail',             state => 'ok',   started => 1780268400, seconds => 845,  size => 9_663_676_416,   files => 96_112,  changed => 0.021,  encrypted => 1 },
	{ id => 3, job => 'database dumps',   state => 'fail', started => 1780270200, seconds => 61,   size => 524_288_000,     files => 12,      changed => 1,      encrypted => 0 },
	{ id => 4, job => 'photos',           state => 'run',  started => 1780295400, seconds => 7290, size => 214_748_364_800, files => 51_207,  changed => 0.0042, encrypted => 0 },
	{ id => 5, job => 'wiki',             state => 'ok',   started => 1780272900, seconds => 42,   size => 157_286_400,     files => 2_311,   changed => 0.087,  encrypted => 1 },
);

# A mutator of your own: any code reference that gets a value and a copy
# of the row, and returns the text.
my $per_second = sub ( $text, $row ) {
	return $text eq '' ? '' : "$text/s";
};

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

my $table = Term::Fabulous::Widget::Table->new(
	id     => 'backups',
	row_id => 'id',
	sort   => [ [ size => 'desc' ] ],

	# The look: a block frame, and colors instead of grid lines.
	border       => 'Outer',
	column_lines => 'none',
	header_line  => 'none',
	stripe_color => '#1c2029',
	columns      => [
		{ key => 'job',     title => 'Job',     mutator => truncate(9) },
		{ key => 'state',   title => 'State',   mutator => lookup( { ok => 'done', fail => 'failed', run => 'running' }, default => 'unknown' ) },
		{ key => 'started', title => 'Started', type    => 'date',   mutator => datetime( '%a %H:%M', utc => 1 ) },
		{ key => 'seconds', title => 'Took',    type    => 'number', mutator => duration() },
		{ key => 'size',    title => 'Size',    type    => 'number', mutator => bytes() },
		{ key => 'files',   title => 'Files',   type    => 'number', mutator => number( decimals => 0 ) },
		{ key => 'changed', title => 'Changed', type    => 'number', mutator => percent( decimals => 1 ) },

		# A computed column: its raw value is bytes per second, shown with
		# two mutators in a row, bytes() and then $per_second.
		{
			key     => 'rate',
			title   => 'Rate',
			type    => 'number',
			value   => sub ($row) { $row->{size} / $row->{seconds} },
			mutator => [ bytes( decimals => 0 ), $per_second ],
		},
		{ key => 'encrypted', title => 'Enc', align => 'center', mutator => boolean( "\x{2714}", '' ) },
	],
	rows => \@backups,
);

my $help   = Term::Fabulous::Widget::Text->new( text => 'Sorted by size. Up, then Left/Right and Enter on a title sorts by another column.', text_color => [ 150, 160, 180, 255 ] );
my $detail = Term::Fabulous::Widget::Text->new( text => 'Move the cursor to see a raw value.',                                               text_color => [ 229, 192, 123, 255 ] );
$root->add_child( $help, $table, $detail );

# The cursor's row: the raw value and the display text of its size.
$table->on(
	CursorMove => sub ($event) {
		my $id = $event->row_id // return;
		$detail->text( sprintf 'Size of %s: raw value %s, display text %s', $table->value( $id, 'job' ), $table->value( $id, 'size' ), $table->display_value( $id, 'size' ) );
		return;
	}
);

my $ui = Term::Fabulous->new( root => $root, width => 100, height => 24 );
$ui->interaction->set_focused_widget($table);
$ui->run;
