#!/usr/bin/env perl

# Term::Fabulous::Widget::VirtualList: a document of fifty thousand
# paragraphs, built paragraph by paragraph as the viewport reaches them.
# Scroll with the mouse wheel, the scrollbar or the keys of less: Up and
# Down or j and k, PageUp and PageDown or b and Space, Home and End or g
# and G. The status line counts the paragraphs built so far.
# Ctrl+C quits.
#
#     perl examples/widgets/virtual-list.pl

use v5.32;
use warnings;
use strict;
use utf8;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../../lib/";

use List::Util qw(max);
use Term::Fabulous;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Scrolling qw(scroll_by_key);
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::VirtualList;

use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM CLAY_TEXT_WRAP_NONE);

use constant PARAGRAPHS  => 50_000;
use constant PER_SECTION => 25;

# Every 25th paragraph is a heading; the others repeat one of a few
# sentences one to three times, so their heights differ.
my @sentences = (
	'A VirtualList keeps its items as data and builds a widget only for the items near the viewport.',
	'Two invisible spacers stand in for the items above and below, so the scrollbar and the wheel see the whole document.',
	'An item is built once; its height is estimated until it has been laid out, then measured.',
	'The item at the top of the viewport stays where it is while the heights around it change.',
);

sub markup_of ($index) {
	return sprintf '[bold #e5c07b]Section %d[/]', $index / PER_SECTION + 1 if $index % PER_SECTION == 0;
	my $sentence = $sentences[ $index % @sentences ];
	return sprintf '[dim]%5d[/]  %s', $index, join ' ', ($sentence) x ( 1 + $index % 3 );
}

my $built    = 0;
my $document = Term::Fabulous::Widget::VirtualList->new(
	id    => 'document',
	count => PARAGRAPHS,
	build => sub ($index) {
		$built++;
		return Term::Fabulous::Widget::Text->new( markup => markup_of($index) );
	},
	estimate => sub ( $index, $columns ) { 1 + int( length( markup_of($index) ) / max( 1, $columns ) ) },
	layout   => {
		sizing    => { width => sizing_grow(), height => sizing_grow() },
		padding   => { left  => 1,             right  => 1 },
		child_gap => 1,
	},
	bordered     => 1,
	border_style => Term::Fabulous::Enum::BorderStyle->Round,
);

my $status = Term::Fabulous::Widget::Text->new( text => '', text_color => [ 150, 160, 180, 255 ], wrap_mode => CLAY_TEXT_WRAP_NONE );
my $root   = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 1,             right  => 1 },
	},
);
$root->add_child( $document, $status );

my $ui = Term::Fabulous->new( width => 80, height => 24, root => $root );

# Keys reach the root: nothing in this program takes the focus. The keys
# of less scroll the list: Home and End go to its first and last
# paragraph, a page is the rows inside the border less one, so the last
# row stays as a landmark.
$root->on(
	KeyPress => sub ($event) {
		scroll_by_key( $ui, $document, $event->main_key_name, keys => 'less' );
		return;
	}
);

# After every frame the status line tells what the frame showed; a
# frame follows only when the text changed.
sub refresh_status () {
	my $visible = $document->visible_items;
	my $text    = sprintf 'Paragraphs %s of %d, %d built  |  keys of less, Ctrl+C quits',
		( defined $visible ? "$visible->{first}-$visible->{last}" : 'none' ), PARAGRAPHS, $built;
	$status->text($text) if $text ne $status->text;
	return 0;    # keeps it for the next frame
}
refresh_status();
$ui->each_draw( \&refresh_status );

$ui->run;
