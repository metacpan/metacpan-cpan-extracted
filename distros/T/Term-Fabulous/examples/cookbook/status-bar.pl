#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::StatusBar;
use Term::Fabulous::Widget::TextArea;
use Clay::UI::Enum::Result;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my $root    = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
my $journal = Term::Fabulous::Widget::TextArea->new( wrap => 1, layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
my $saved   = '';

# The parts on the right are read whenever a frame is drawn, so they
# follow the typing without any code that updates them.
my $status = Term::Fabulous::Widget::StatusBar->new(
	message => 'Write today\'s entry. Ctrl+S saves, Ctrl+Q quits.',
	timeout => 3,
	parts   => sub {
		my $text  = $journal->value;
		my $words = () = $text =~ /\S+/g;
		return ( ( $text ne $saved ? [ 'unsaved', 'accent' ] : () ), [ "$words words", 'dim' ] );
	},
);
$root->add_child( $journal, $status );

my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );

$root->on(
	KeyPress => sub ($event) {
		my $key = $event->key_name // '';
		if ( $key eq 'Ctrl+S' ) {
			my $text = $journal->value;
			if ( $text =~ /\S/ ) {
				$saved = $text;
				$status->message( 'Saved the entry.', 'success' );
			}
			else {
				$status->message( 'Nothing to save yet.', 'warning' );
			}
			return;
		}
		if ( $key eq 'Ctrl+Q' ) {
			$ui->loop->stop;
			return;
		}
		return Clay::UI::Enum::Result->CONTINUE;
	}
);

$ui->interaction->set_focused_widget($journal);
$ui->run;
