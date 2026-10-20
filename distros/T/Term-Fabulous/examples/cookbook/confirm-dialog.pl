#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Dialog;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::TextArea;
use Clay::UI::Enum::Result;
use Clay::XS qw(sizing_grow sizing_fixed CLAY_TOP_TO_BOTTOM);

sub text ( $string, $color = [ 220, 220, 220, 255 ] ) {
	return Term::Fabulous::Widget::Text->new( text => $string, text_color => $color );
}

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);
my $notes = Term::Fabulous::Widget::TextArea->new( id => 'notes', layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
$root->add_child( text('Type some notes. Ctrl+Q asks before quitting.'), $notes );

my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );

# The dialog is built once and opened as often as needed. Its look
# (border, background, padding), its title and its buttons come with
# the widget; pressing a button answers with its id, Escape answers
# cancel.
my $dialog = Term::Fabulous::Widget::Dialog->new(
	id      => 'confirm',
	title   => 'Really quit?',
	buttons => [ { id => 'quit', label => 'Quit', primary => 1 }, { id => 'cancel', label => 'Cancel' } ],
	layout  => { sizing => { width => sizing_fixed(44) } },
);
$dialog->add_child( text('Unsaved notes are lost.') );
$dialog->on( Answer => sub ($event) { $ui->loop->stop if $event->button eq 'quit'; return } );

$root->on(
	KeyPress => sub ($event) {
		return Clay::UI::Enum::Result->CONTINUE unless ( $event->key_name // '' ) eq 'Ctrl+Q';
		$dialog->open($ui);
		return;
	}
);

$ui->interaction->set_focused_widget($notes);
$ui->run;
