#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::TextField;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 1,             right  => 1 },
	},
);
my $name = Term::Fabulous::Widget::TextField->new( id => 'name', placeholder => 'Your name', layout => { sizing => { width => sizing_grow() } } );
my $help = Term::Fabulous::Widget::Text->new( text => 'Enter answers, Escape cancels.', text_color => [ 150, 160, 180, 255 ] );
$root->add_child( Term::Fabulous::Widget::Text->new( text => 'What is your name?', text_color => [ 230, 230, 230, 255 ] ), $name, $help );

# Three rows below the shell's output instead of the whole screen.
my $ui = Term::Fabulous->new( root => $root, width => 80, height => 3, inline => 3 );
$ui->interaction->set_focused_widget($name);

my $answered = 0;
$root->on(
	Submit => sub ($event) {
		$answered = 1;
		$help->text('Thank you!');    # drawn before run returns, and left on the screen
		$ui->loop->stop;
		return;
	}
);
$root->on(
	KeyPress => sub ($event) {
		my $key = $event->key_name // return;
		$ui->loop->stop if $key eq 'Escape';
		return;
	}
);

$ui->run;
say $answered ? 'Hello, ' . $name->value . '!' : 'Cancelled.';
