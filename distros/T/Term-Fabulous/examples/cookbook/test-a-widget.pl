#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;
use Clay::XS qw(sizing_fixed sizing_grow CLAY_TOP_TO_BOTTOM);
use Term::Fabulous;
use Term::Fabulous::Terminal::Memory;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Button;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::TextField;

my $field = Term::Fabulous::Widget::TextField->new( preferred_columns => 10, max_length => 8 );
my $save  = Term::Fabulous::Widget::Button->new(
	background_color => [ 40, 90, 160, 255 ],
	layout           => { sizing => { width => sizing_fixed(6), height => sizing_fixed(1) }, padding => { left => 1 } },
);
$save->add_child( Term::Fabulous::Widget::Text->new( text => 'Save', text_color => [ 255, 255, 255, 255 ] ) );

my $root = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() }, child_gap => 1 } );
$root->add_child( $field, $save );

my ( @changes, @saved );
$field->on( Change => sub ($event) { push @changes, $event->value; return } );
$save->on( Activate => sub ($event) { push @saved, $field->value; return } );

# The program's widget tree on a terminal in memory, 20 columns by 3 rows.
my $terminal = Term::Fabulous::Terminal::Memory->new( width => 20, height => 3 );
my $ui       = Term::Fabulous->new( root => $root, width => 20, height => 3, terminal => $terminal );
$ui->step;    # opens the terminal and draws the first frame

# Tab focuses the field; the keys go to it as on a real terminal.
$terminal->press_key('Tab')->type_text('hello')->press_key('Left')->type_text('X');
$ui->step;
is $field->value, 'hellXo', 'typing and cursor movement';
is $changes[-1],  'hellXo', 'Change carries the new text';

$terminal->type_text('abcdef');
$ui->step;
is $field->value, 'hellXabo', 'max_length stops the input at 8 characters';

# The field is 10 columns wide and has a background color, so its
# empty cells are kept as spaces.
is [ $terminal->lines ], [ 'hellXabo  ', '', ' Save ' ], 'what the screen shows';

# A click on the button: hit-tested, pressed and released like a real one.
$terminal->click( 2, 2 );
$ui->step;
is \@saved, ['hellXabo'], 'the click activates the button';
ref_is $ui->interaction->get_focused_widget, $save, 'and focuses it';

done_testing;
