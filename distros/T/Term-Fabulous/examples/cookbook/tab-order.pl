#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::TextField;
use Clay::UI::Role::Interaction::HasFocusOrder;
use Clay::XS qw(sizing_grow);

# A box that decides the Tab order of everything inside it. It must be
# the root: with nothing focused, only the root is asked.
class My::OrderedBox :isa(Term::Fabulous::Widget::Box) :does(Clay::UI::Role::Interaction::HasFocusOrder) :strict(params) {
	field @order;

	method focus_order (@widgets) {
		@order = @widgets;
		return $self;
	}

	method _neighbour ($direction) {
		my $focused = $self->ui->interaction->get_focused_widget;
		my ($index) = grep { defined $focused && $order[$_] == $focused } 0 .. $#order;
		return $order[ $direction > 0 ? 0 : -1 ] unless defined $index;
		return $order[ ( $index + $direction ) % @order ];
	}

	method get_next_focus ()     { return $self->_neighbour(1) }
	method get_previous_focus () { return $self->_neighbour(-1) }
}

my %field = map { $_ => Term::Fabulous::Widget::TextField->new( id => $_, placeholder => ucfirst, preferred_columns => 12 ) } qw(street city zip);
my $root  = My::OrderedBox->new(
	layout => { sizing => { width => sizing_grow(), height => sizing_grow() }, padding => { left => 2, top => 1 }, child_gap => 2 },
);

# Shown left to right as street, city, zip; Tab goes street, zip, city.
$root->add_child( @field{qw(street city zip)} );
$root->focus_order( @field{qw(street zip city)} );

Term::Fabulous->new( root => $root, width => 80, height => 24 )->run;
