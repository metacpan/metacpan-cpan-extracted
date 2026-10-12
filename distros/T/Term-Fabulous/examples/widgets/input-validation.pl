#!/usr/bin/env perl

# The invalid look of the input widgets: what a value that is empty
# but required, or that its validator rejects, looks like in a field
# with and without a border, a check box and a dropdown, with an
# invalid_color of its own, in a theme variant, and while disabled.
# Type into the first field to see the look follow the value; Tab
# moves the focus, Ctrl+C quits.
#
#     perl examples/widgets/input-validation.pl

use v5.32;
use warnings;
use strict;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../../lib/";

use Term::Fabulous;
use Term::Fabulous::Theme;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Checkbox;
use Term::Fabulous::Widget::Dropdown;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::TextField;

use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

# The dark theme with a variant "calm" for the text inputs (the family
# text_input), whose invalid text and border are drawn in the warning
# color instead of the danger red.
my $theme = Term::Fabulous::Theme->new(
	name     => 'calm-invalid',
	extends  => 'dark',
	variants => { 'text_input.calm' => { 'text.invalid' => 'warning', 'border.color.invalid' => 'warning' } },
);

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

sub email_field (%parameters) {
	return Term::Fabulous::Widget::TextField->new( validator => 'email', placeholder => 'name@example.com', preferred_columns => 24, %parameters );
}

my $typed = state_row( 'typing, focused', email_field() );
state_row( 'valid',              email_field( value => 'ada@example.com' ) );
state_row( 'invalid',            email_field( value => 'ada@' ) );
state_row( 'invalid, border',    email_field( value => 'ada@', bordered => 1 ) );
state_row( 'required, empty',    Term::Fabulous::Widget::TextField->new( required => 1, placeholder => 'Your name', preferred_columns => 24 ) );
state_row( 'required, border',   Term::Fabulous::Widget::TextField->new( required => 1, placeholder => 'Your name', preferred_columns => 22, bordered => 1 ) );
state_row( 'required check box', Term::Fabulous::Widget::Checkbox->new( required => 1, label   => 'I accept the terms' ) );
state_row( 'required dropdown',  Term::Fabulous::Widget::Dropdown->new( required => 1, options => [qw(Red Green Blue)], placeholder => 'Choose a color' ) );
state_row( 'invalid_color',      email_field( value => 'ada@', invalid_color => '#c678dd' ) );
state_row( 'theme variant',      email_field( value => 'ada@', bordered      => 1, classes => ['calm'] ) );
state_row( 'disabled',           email_field( value => 'ada@', disabled      => 1 ) );

my $ui = Term::Fabulous->new( width => 80, height => 24, root => $root, theme => $theme );
$ui->interaction->set_focused_widget($typed);
$ui->run;
