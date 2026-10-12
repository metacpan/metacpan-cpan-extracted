#!/usr/bin/env perl

# Term::Fabulous::Widget::TextField: a focused field to type in, an
# empty one with a placeholder, a masked password and a disabled field.
# Shift with the arrow keys selects text, Tab moves the focus, Ctrl+C
# quits.
#
#     perl examples/widgets/text-field.pl

use v5.32;
use warnings;
use strict;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../../lib/";

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::TextField;

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

my $name = state_row( 'focused', Term::Fabulous::Widget::TextField->new( placeholder => 'Your name', preferred_columns => 32 ) );
state_row( 'placeholder', Term::Fabulous::Widget::TextField->new( placeholder => 'name@example.com', preferred_columns => 32 ) );
state_row( 'masked',      Term::Fabulous::Widget::TextField->new( value       => 'correct horse',    mask     => '*', preferred_columns => 32 ) );
state_row( 'disabled',    Term::Fabulous::Widget::TextField->new( value       => 'Not editable',     disabled => 1,   preferred_columns => 32 ) );

my $ui = Term::Fabulous->new( width => 80, height => 24, root => $root );
$ui->interaction->set_focused_widget($name);
$ui->run;
