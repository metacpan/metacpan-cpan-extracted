#!/usr/bin/env perl

# Term::Fabulous::Widget::RadioGroup and RadioButton: a group in a row, a
# group in a column and a disabled group. The group holds the value and
# takes the focus for all its buttons. Tab moves between the groups, the
# arrow keys choose a button, Ctrl+C quits.
#
#     perl examples/widgets/radio.pl

use v5.32;
use warnings;
use strict;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../../lib/";

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::RadioButton;
use Term::Fabulous::Widget::RadioGroup;
use Term::Fabulous::Widget::Text;

use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM CLAY_LEFT_TO_RIGHT);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

sub state_row ( $state, $widget ) {
	my $label = Term::Fabulous::Widget::Box->new( width_group => 1 );
	$label->add_child( Term::Fabulous::Widget::Text->new( text => $state, text_color => [ 150, 160, 180, 255 ] ) );
	my $row = Term::Fabulous::Widget::Box->new( layout => { child_gap => 2 } );
	$row->add_child( $label, $widget );
	$root->add_child($row);
	return $widget;
}

# A group with one button per [ label, value ] pair.
sub radio_group ( $value, $direction, $choices, %options ) {
	my $group = Term::Fabulous::Widget::RadioGroup->new( value => $value, layout => { layout_direction => $direction, child_gap => $direction == CLAY_LEFT_TO_RIGHT ? 2 : 0 }, %options );
	$group->add_child( Term::Fabulous::Widget::RadioButton->new( label => $_->[0], value => $_->[1] ) ) foreach @$choices;
	return $group;
}

my $sizes = state_row( 'in a row', radio_group( 'm', CLAY_LEFT_TO_RIGHT, [ [ Small => 's' ], [ Medium => 'm' ], [ Large => 'l' ] ] ) );
state_row( 'in a column', radio_group( 'express', CLAY_TOP_TO_BOTTOM, [ [ 'Standard shipping' => 'standard' ], [ 'Express shipping' => 'express' ], [ 'Pick up in store' => 'pickup' ] ] ) );
state_row( 'disabled', radio_group( 'card', CLAY_LEFT_TO_RIGHT, [ [ Card => 'card' ], [ Invoice => 'invoice' ] ], disabled => 1 ) );

my $ui = Term::Fabulous->new( width => 80, height => 24, root => $root );
$ui->interaction->set_focused_widget($sizes);
$ui->run;
