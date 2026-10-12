#!/usr/bin/env perl

# Term::Fabulous::Widget::SegmentedControl in its forms: a focused
# control, one stretched to the full width, one with a disabled
# segment, a vertical one and a disabled one. Tab moves the focus, Left
# and Right (or the digits, Home and End) choose a segment, so does a
# click, Ctrl+C quits.
#
#     perl examples/widgets/segmented-control.pl

use v5.32;
use warnings;
use strict;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../../lib/";

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::SegmentedControl;
use Term::Fabulous::Widget::Text;

use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
	},
);

# A row: the name of the state, then the widget showing it.
sub state_row ( $state, $widget ) {
	my $label = Term::Fabulous::Widget::Box->new( width_group => 1 );
	$label->add_child( Term::Fabulous::Widget::Text->new( text => $state, text_color => [ 150, 160, 180, 255 ] ) );
	my $row = Term::Fabulous::Widget::Box->new( layout => { child_gap => 2, sizing => { width => sizing_grow() } } );
	$row->add_child( $label, $widget );
	$root->add_child($row);
	return $widget;
}

my $focused = state_row( 'focused', Term::Fabulous::Widget::SegmentedControl->new( options => [qw(Day Week Month Year)], value => 'Week' ) );
state_row( 'full width',   Term::Fabulous::Widget::SegmentedControl->new( options => [qw(List Grid Map)], value => 'List', layout => { sizing => { width => sizing_grow() } } ) );
state_row( 'one disabled', Term::Fabulous::Widget::SegmentedControl->new( options => [ 'Free', 'Pro', { label => 'Enterprise', disabled => 1 } ], value => 'Pro' ) );
state_row( 'vertical',     Term::Fabulous::Widget::SegmentedControl->new( options => [qw(General Network Users)], value => 'Network', vertical => 1, segment_padding => 2 ) );
state_row( 'disabled',     Term::Fabulous::Widget::SegmentedControl->new( options => [qw(Light Dark)],            value => 'Dark',    disabled => 1 ) );

my $ui = Term::Fabulous->new( width => 80, height => 24, root => $root );
$ui->interaction->set_focused_widget($focused);
$ui->run;
