#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous::Static;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Button;
use Term::Fabulous::Widget::Text;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

# One look per state, applied by a single function.
sub restyle ($item) {
	$item->background_color( $item->has_state('selected') ? [ 60, 90, 140, 255 ] : [ 30, 35, 50, 255 ] );
	return;
}

my $menu = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow() } } );
my @items;
foreach my $name (qw(Open Save Quit)) {
	my $item = Term::Fabulous::Widget::Button->new(
		id      => lc $name,
		classes => [ 'menu-item', $name eq 'Quit' ? 'danger' : () ],
		layout  => { sizing => { width => sizing_grow() }, padding => { left => 1 } },
	);
	$item->add_child( Term::Fabulous::Widget::Text->new( text => $name, text_color => [ 230, 230, 230, 255 ] ) );
	restyle($item);
	push @items, $item;
}
$menu->add_child(@items);

# The derived states (hovered, pressed, focused) need a UI that owns the
# tree; a Static one is enough here.
my $page = Term::Fabulous::Static->new( root => $menu, width => 20 );

# User states: any name you like.
$items[1]->add_state('selected');
$items[2]->toggle_state('selected')->toggle_state('selected');    # on and off again
restyle($_) foreach @items;

# Derived states follow the interaction tracker and cannot be set.
$page->interaction->set_focused_widget( $items[0] );

# The menu, with Save in the color of the selected state (colors only when
# STDOUT is a terminal), and the states and classes of each item.
$page->print;

foreach my $item (@items) {
	printf "%-5s states: %-18s classes: %s\n", $item->id, join( ',', sort $item->states ), join( ' ', sort $item->get_classes );
}
printf "Save selected: %d, Open focused: %d\n", $items[1]->has_state('selected'), $items[0]->has_state('focused');
eval { $items[0]->add_state('focused'); 1 } or print "add_state('focused') dies\n";
