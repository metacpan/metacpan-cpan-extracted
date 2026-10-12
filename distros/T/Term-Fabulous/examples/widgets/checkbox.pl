#!/usr/bin/env perl

# Term::Fabulous::Widget::Checkbox in its states: unchecked, checked,
# indeterminate, focused and disabled. Tab moves the focus, Space or
# Enter toggles the focused box, Ctrl+C quits.
#
#     perl examples/widgets/checkbox.pl

use v5.32;
use warnings;
use strict;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../../lib/";

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Checkbox;
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

my $focused = state_row( 'focused', Term::Fabulous::Widget::Checkbox->new( label => 'Remember me' ) );
state_row( 'unchecked',     Term::Fabulous::Widget::Checkbox->new( label => 'Send me the newsletter' ) );
state_row( 'checked',       Term::Fabulous::Widget::Checkbox->new( label => 'I accept the terms',             checked       => 1 ) );
state_row( 'indeterminate', Term::Fabulous::Widget::Checkbox->new( label => 'Select all (some are selected)', indeterminate => 1 ) );
state_row( 'disabled',      Term::Fabulous::Widget::Checkbox->new( label => 'Not available here',             disabled      => 1 ) );

my $ui = Term::Fabulous->new( width => 80, height => 24, root => $root );
$ui->interaction->set_focused_widget($focused);
$ui->run;
