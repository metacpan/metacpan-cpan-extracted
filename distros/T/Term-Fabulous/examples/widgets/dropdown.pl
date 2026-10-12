#!/usr/bin/env perl

# Term::Fabulous::Widget::Dropdown: one showing its placeholder, one with
# a selected option, and one whose list is open. Tab moves the focus;
# Enter, Space, Alt+Down or F4 open the list, Up and Down move in it,
# Enter chooses, Escape closes it. Ctrl+C quits.
#
#     perl examples/widgets/dropdown.pl

use v5.32;
use warnings;
use strict;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../../lib/";

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Dropdown;
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

my @countries = ( [ Germany => 'DE' ], [ France => 'FR' ], [ Italy => 'IT' ], [ Spain => 'ES' ], [ 'United Kingdom' => 'GB' ] );

state_row( 'placeholder', Term::Fabulous::Widget::Dropdown->new( placeholder => 'Choose a country', options => \@countries ) );
state_row( 'selected',    Term::Fabulous::Widget::Dropdown->new( options     => \@countries,        value   => 'FR' ) );
my $open = state_row( 'open', Term::Fabulous::Widget::Dropdown->new( options => [qw(Red Orange Yellow Green Blue Violet)], value => 'Green' ) );

my $ui = Term::Fabulous->new( width => 80, height => 24, root => $root );
$ui->interaction->set_focused_widget($open);
$ui->run;
