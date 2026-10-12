#!/usr/bin/env perl

# Term::Fabulous::Widget::StarRating in its forms: a focused rating, one
# with half stars that shows its value, a read-only one, one out of ten
# without gaps, and a disabled one. Tab moves the focus, Left and Right
# (or the digits, Home and End) change the value, the mouse clicks a
# star, Ctrl+C quits.
#
#     perl examples/widgets/star-rating.pl

use v5.32;
use warnings;
use strict;
use utf8;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../../lib/";

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::StarRating;
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
	my $row = Term::Fabulous::Widget::Box->new( layout => { child_gap => 2 } );
	$row->add_child( $label, $widget );
	$root->add_child($row);
	return $widget;
}

my $focused = state_row( 'focused', Term::Fabulous::Widget::StarRating->new( value => 3, show_value => 1 ) );
state_row( 'half stars',  Term::Fabulous::Widget::StarRating->new( value => 3.5, half      => 1, show_value => 1, value_format => '%.1f' ) );
state_row( 'read-only',   Term::Fabulous::Widget::StarRating->new( value => 4,   read_only => 1 ) );
state_row( 'ten, no gap', Term::Fabulous::Widget::StarRating->new( value => 7,   max       => 10, gap => 0, show_value => 1 ) );
state_row( 'disabled',    Term::Fabulous::Widget::StarRating->new( value => 2,   disabled  => 1 ) );

my $ui = Term::Fabulous->new( width => 80, height => 24, root => $root );
$ui->interaction->set_focused_widget($focused);
$ui->run;
