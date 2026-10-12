#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Prompt;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::TextArea;
use Clay::UI::Enum::Result;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);
my $notes = Term::Fabulous::Widget::TextArea->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
$root->add_child( Term::Fabulous::Widget::Text->new( text => 'Type some notes. Ctrl+Q asks before quitting.' ), $notes );

my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );

$root->on(
	KeyPress => sub ($event) {
		return Clay::UI::Enum::Result->CONTINUE unless ( $event->key_name // '' ) eq 'Ctrl+Q';
		Term::Fabulous::Widget::Prompt->confirm(
			$ui,
			title   => 'Quit?',
			message => 'Your notes are not saved anywhere.',
			ok      => 'Quit',
			cancel  => 'Keep writing',
			focus   => 'cancel',
		)->on(
			Answer => sub ($event) {
				$ui->loop->stop if $event->button eq 'ok';
				return;
			}
		);
		return;
	}
);

$ui->interaction->set_focused_widget($notes);
$ui->run;
