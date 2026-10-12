#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Dropdown;
use Term::Fabulous::Widget::RadioButton;
use Term::Fabulous::Widget::RadioGroup;
use Term::Fabulous::Widget::Slider;
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

# Options are labels, [ label, value ] pairs or { label, value } hashes.
my $country = Term::Fabulous::Widget::Dropdown->new(
	id          => 'country',
	placeholder => 'Choose a country',
	options     => [ [ 'Germany' => 'DE' ], [ 'France' => 'FR' ], [ 'Italy' => 'IT' ], { label => 'United Kingdom', value => 'GB' } ],
);

# The group holds the value; each button says which value it stands for.
my $shipping = Term::Fabulous::Widget::RadioGroup->new( id => 'shipping', value => 'standard', layout => { layout_direction => CLAY_LEFT_TO_RIGHT, child_gap => 2 } );
$shipping->add_child( Term::Fabulous::Widget::RadioButton->new( label => $_->[0], value => $_->[1] ) )
	foreach [ 'Standard' => 'standard' ], [ 'Express' => 'express' ], [ 'Pick up' => 'pickup' ];

# value_format may be a code reference.
my $tip = Term::Fabulous::Widget::Slider->new(
	id           => 'tip',
	min          => 0,
	max          => 20,
	step         => 2.5,
	value        => 10,
	value_format => sub ($percent) { sprintf '%4.1f %%', $percent },
);

my $status = Term::Fabulous::Widget::Text->new( text => 'Nothing chosen yet.', text_color => [ 150, 200, 255, 255 ] );
$root->add_child( $country, $shipping, $tip, $status );

$root->on(
	Change => sub ($event) {
		$status->text( sprintf '%s: %s', $event->target->id, $event->value // 'none' );
		return;
	}
);

# Choosing from code fires no Change; the user's choices do.
$country->value('FR');

my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );
$ui->interaction->set_focused_widget($country);
$ui->run;
