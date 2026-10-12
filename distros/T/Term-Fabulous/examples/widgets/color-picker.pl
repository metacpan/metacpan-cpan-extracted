#!/usr/bin/env perl

# Term::Fabulous::Widget::ColorPicker: a picker with named swatches and
# one without, each with a line that shows the value it chose. Tab moves
# from part to part, Up and Down pick a swatch, Left and Right move a
# slider, typing a color sets it, Ctrl+C quits.
#
#     perl examples/widgets/color-picker.pl

use v5.32;
use warnings;
use strict;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../../lib/";

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::ColorPicker;
use Term::Fabulous::Widget::Text;

use Clay::UI::Enum::Result;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

# A picker, then a line that shows what it chose.
sub picker_with_line (%parameters) {
	my $picker = Term::Fabulous::Widget::ColorPicker->new(%parameters);
	my $line   = Term::Fabulous::Widget::Text->new( text => chosen_text($picker) );
	$picker->on(
		Change => sub ($event) {
			$line->text( chosen_text($picker) );
			return Clay::UI::Enum::Result->CONTINUE;
		}
	);
	$root->add_child( $picker, $line );
	return $picker;
}

sub chosen_text ($picker) {
	my $value = $picker->value // return 'Chosen: nothing';
	my $rgba  = $picker->rgba  // return "Chosen: $value (no color)";
	return "Chosen: $value (" . join( ', ', @$rgba ) . ')';
}

my $with_swatches = picker_with_line(
	id        => 'paint',
	value     => 'orange',
	list_rows => 6,
	swatches  => [
		[ red    => 'Red',    '#e06c75' ],
		[ orange => 'Orange', '#d19a66' ],
		[ yellow => 'Yellow', '#e5c07b' ],
		[ green  => 'Green',  '#98c379' ],
		[ blue   => 'Blue',   '#61afef' ],
		[ none   => 'No color' ],
	],
);
picker_with_line( id => 'opaque', value => '#2e8b57', alpha => 0, sliders => 'hsl' );

my $ui = Term::Fabulous->new( width => 80, height => 24, root => $root );
$ui->interaction->set_focused_widget( $with_swatches->find_by_id('paint/list') );
$ui->run;
