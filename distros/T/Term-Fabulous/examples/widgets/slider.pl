#!/usr/bin/env perl

# Term::Fabulous::Widget::Slider: a focused slider with a percentage, one
# that formats its value with code, and a disabled one. Tab moves the
# focus, Left and Right (or PageUp, PageDown, Home, End) change the
# value, Ctrl+C quits.
#
#     perl examples/widgets/slider.pl

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
use Term::Fabulous::Widget::Slider;
use Term::Fabulous::Widget::Text;

use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

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

my $volume = state_row( 'focused', Term::Fabulous::Widget::Slider->new( min => 0, max => 100, step => 5, value => 65, value_format => '%d%%', preferred_columns => 36 ) );
state_row(
	'formatted',
	Term::Fabulous::Widget::Slider->new(
		min               => 15,
		max               => 30,
		step              => 0.5,
		value             => 21.5,
		value_format      => sub ($celsius) { sprintf '%.1f °C', $celsius },
		preferred_columns => 36,
	)
);
state_row( 'disabled', Term::Fabulous::Widget::Slider->new( value => 30, disabled => 1, preferred_columns => 36 ) );

my $ui = Term::Fabulous->new( width => 80, height => 24, root => $root );
$ui->interaction->set_focused_widget($volume);
$ui->run;
