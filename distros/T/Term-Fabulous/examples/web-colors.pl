#!/usr/bin/env perl

# Every color of Term::Fabulous::Enum::WebColor in a grid: a swatch with
# the hex value on it and the name below. The number of columns follows
# the terminal width and is recomputed on every resize; the grid scrolls
# when it does not fit. A dropdown sorts the colors by hue, brightness,
# saturation or name.
#
#     perl examples/web-colors.pl
#
# The mouse wheel scrolls. Up, Down, PageUp, PageDown, Home and End scroll
# by keyboard; once a key has scrolled, the wheel no longer does (see
# child_offset in Term::Fabulous::Widget::ScrollBox). Tab or a click
# focuses the dropdown, which then takes the arrow keys and letters for
# itself; Tab again gives them back to the grid. q (while the dropdown is
# not focused), Ctrl+Q or Ctrl+C quits.

use v5.32;
use warnings;
use strict;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../lib/";

use IO::Async::Loop;
use IO::Async::Timer::Countdown;
use List::Util qw(max min);
use POSIX qw(ceil);
use Term::Fabulous;
use Term::Fabulous::Enum::WebColor;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Dropdown;
use Term::Fabulous::Widget::ScrollBox;
use Term::Fabulous::Widget::Text;
use Clay::UI::Enum::Result;
use Clay::XS qw(sizing_grow sizing_fit sizing_fixed CLAY_TOP_TO_BOTTOM);

use constant CELL_WIDTH   => 22;    # the longest name, LightGoldenRodYellow, plus a margin
use constant CELL_HEIGHT  => 3;    # two rows of swatch, one row of name
use constant COLUMN_GAP   => 2;
use constant ROW_GAP      => 1;
use constant PAGE_PADDING => 2;
use constant HEADER_ROWS  => 2;    # the heading and the gap below it

my @colors = Term::Fabulous::Enum::WebColor->values;

# Perceived brightness of a color, 0 (black) to 255 (white).
sub luma ($color) {
	my ( $r, $g, $b ) = $color->to_rgba;
	return 0.299 * $r + 0.587 * $g + 0.114 * $b;
}

# The sort orders the dropdown offers; each maps a color to the keys it
# is sorted by, ascending. Name keeps the enumeration's alphabetical order.
# Pure greys have no hue of their own and go after the colors, by lightness.
my %sort_keys_by_metric = (
	hue => sub ($color) {
		my ( $hue, $saturation, $lightness ) = $color->to_hsl;
		return ( $saturation == 0 ? 360 : $hue, $lightness );
	},
	brightness => sub ($color) { return luma($color) },
	saturation => sub ($color) { return ( $color->to_hsl )[1] },
	name       => sub ($color) { return $color->ordinal },
);
my $metric = 'hue';

sub sorted_colors () {
	my $keys_of = $sort_keys_by_metric{$metric};
	my @keyed   = map { [ $_, $keys_of->($_) ] } @colors;
	return map { $_->[0] } sort { $a->[1] <=> $b->[1] || ( $a->[2] // 0 ) <=> ( $b->[2] // 0 ) } @keyed;
}

sub text ( $string, $color ) {
	return Term::Fabulous::Widget::Text->new( text => $string, text_color => $color );
}

# Black text on light colors, white text on dark ones.
sub contrasting_text_color ($color) {
	return luma($color) > 150 ? [ 0, 0, 0, 255 ] : [ 255, 255, 255, 255 ];
}

sub color_cell ($color) {
	my $swatch = Term::Fabulous::Widget::Box->new(
		background_color => $color,
		layout           => { sizing => { width => sizing_grow(), height => sizing_fixed(2) }, padding => { left => 1 } },
	);
	$swatch->add_child( text( substr( $color->hexString, 0, 7 ), contrasting_text_color($color) ) );

	my $cell = Term::Fabulous::Widget::Box->new(
		layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_fixed(CELL_WIDTH), height => sizing_fit() } },
	);
	$cell->add_child( $swatch, text( $color->name, [ 200, 210, 230, 255 ] ) );
	return $cell;
}

my $grid = Term::Fabulous::Widget::ScrollBox->new(
	id     => 'grid',
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => PAGE_PADDING,  right  => PAGE_PADDING, top => 1, bottom => 1 },
		child_gap        => ROW_GAP,
	},
);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { top   => 1 },
		child_gap        => 1,
	},
);
my $sort_by = Term::Fabulous::Widget::Dropdown->new(
	id      => 'sort_by',
	value   => $metric,
	options => [ [ Hue => 'hue' ], [ Brightness => 'brightness' ], [ Saturation => 'saturation' ], [ Name => 'name' ] ],
);
my $heading = Term::Fabulous::Widget::Box->new( layout => { padding => { left => PAGE_PADDING }, child_gap => 2 } );
$heading->add_child(
	text( scalar(@colors) . ' web colors. Wheel or arrow keys scroll, q quits.', [ 220, 220, 220, 255 ] ),
	text( 'Sort by',                                                             [ 160, 170, 190, 255 ] ),
	$sort_by,
);
$root->add_child( $heading, $grid );

my $ui = Term::Fabulous->new( width => 80, height => 24, root => $root );

# Lays the colors out in as many columns as the width allows, one row
# box per grid row, replacing whatever the grid held before.
my $row_count = 1;

sub build_grid ($width) {
	my $usable = $width - 2 * PAGE_PADDING;    # the grid's padding
	my $columns = max( 1, int( ( $usable + COLUMN_GAP ) / ( CELL_WIDTH + COLUMN_GAP ) ) );
	$row_count = ceil( @colors / $columns );

	my @sorted = sorted_colors();
	$grid->clear_children;
	foreach my $row_index ( 0 .. $row_count - 1 ) {
		my $row = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_fit(), height => sizing_fit() }, child_gap => COLUMN_GAP } );
		$row->add_child( map { color_cell($_) } @sorted[ $row_index * $columns .. min( $#sorted, ( $row_index + 1 ) * $columns - 1 ) ] );
		$grid->add_child($row);
	}
	return;
}

$sort_by->on(
	Change => sub ($event) {
		$metric = $event->value;
		build_grid( $ui->width );
		return Clay::UI::Enum::Result->CONTINUE;
	}
);

# Keyboard scrolling moves the content by whole cells and stops at the ends.
my $scrolled_rows = 0;

sub content_height () {
	return $row_count * CELL_HEIGHT + ( $row_count - 1 ) * ROW_GAP + 2;    # plus the grid's top and bottom padding
}

sub scroll_to ($rows) {
	my $visible = $ui->height - HEADER_ROWS - 1;    # minus the root's top padding
	$scrolled_rows = max( 0, min( $rows, content_height() - $visible ) );
	$grid->child_offset( { x => 0, y => -$scrolled_rows } );
	return;
}

sub scroll_by ($rows) {
	scroll_to( $scrolled_rows + $rows );
	return;
}

my %action_by_key = (
	'Up'       => sub { scroll_by(-1) },
	'Down'     => sub { scroll_by(1) },
	'PageUp'   => sub { scroll_by( -( $ui->height - HEADER_ROWS ) ) },
	'PageDown' => sub { scroll_by( $ui->height - HEADER_ROWS ) },
	'Home'     => sub { scroll_to(0) },
	'End'      => sub { scroll_to( content_height() ) },
	'q'        => sub { $ui->loop->stop },
	'Ctrl+Q'   => sub { $ui->loop->stop },
);
$root->on(
	KeyPress => sub ($event) {
		my $action = $action_by_key{ $event->key_name // '' } or return;
		$action->();
		return;
	}
);

# The terminal size is only known once run has started: build the grid
# from the loop, and again after every resize.
$root->on(
	Resize => sub ($event) {
		return unless $event->is_post_event;
		build_grid( $event->width );
		scroll_to($scrolled_rows) if $grid->child_offset;
		return;
	}
);
my $first_layout = IO::Async::Timer::Countdown->new( delay => 0, on_expire => sub { build_grid( $ui->width ); return } );
$first_layout->start;
IO::Async::Loop->new->add($first_layout);

$ui->run;
