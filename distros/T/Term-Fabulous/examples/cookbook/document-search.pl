#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/lib";    # where My/Markdown.pm lives

use Clay::UI::Enum::Result;
use Clay::XS qw(sizing_grow sizing_fixed CLAY_LEFT_TO_RIGHT CLAY_TOP_TO_BOTTOM CLAY_TEXT_WRAP_NONE);
use My::Markdown;
use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::DocumentView;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::TextField;

my $view = Term::Fabulous::Widget::DocumentView->new(
	id       => 'manual',
	document => My::Markdown->parse_file("$FindBin::Bin/documents/snapback.md"),
	layout   => { sizing => { width => sizing_grow(), height => sizing_grow() }, padding => { left => 1, right => 1 } },
);

# The bottom line: a search field on the left, the position on the right.
my $field = Term::Fabulous::Widget::TextField->new(
	placeholder => '/ to search',
	layout      => { sizing => { width => sizing_fixed(24) } },
);
my $position = Term::Fabulous::Widget::Text->new( text => '', wrap_mode => CLAY_TEXT_WRAP_NONE, text_color => [ 150, 160, 180, 255 ] );
my $line     = Term::Fabulous::Widget::Box->new(
	layout => { layout_direction => CLAY_LEFT_TO_RIGHT, sizing => { width => sizing_grow() }, padding => { left => 1, right => 1 }, child_gap => 2 },
);
$line->add_child( $field, $position );

my $root = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
$root->add_child( $view, $line );

my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );

# / moves to the search field, Enter there searches and returns to the
# document, where n and N step through the matches and Escape ends the
# search.
$view->on(
	KeyPress => sub ($event) {
		return Clay::UI::Enum::Result->CONTINUE unless ( $event->key_name // '' ) eq '/';
		$ui->interaction->set_focused_widget($field);
		return;
	}
);
$field->on(
	KeyPress => sub ($event) {
		return Clay::UI::Enum::Result->CONTINUE unless ( $event->key_name // '' ) eq 'Escape';
		$ui->interaction->set_focused_widget($view);
		return;
	}
);
$field->on(
	Submit => sub ($event) {
		$view->search( $event->value );
		$ui->interaction->set_focused_widget($view);
		return;
	}
);

# After every frame that shows something new, the view says what it
# shows: the section at the top, how far down the reader is, and the
# search.
$view->on(
	ViewChange => sub ($event) {
		my $search
			= !defined $event->query ? ''
			: $event->matches        ? sprintf( 'match %d of %d  ', $event->match, $event->matches )
			:                          sprintf( 'no "%s"  ', $event->query );
		$position->text( sprintf '%s%s  %d%%', $search, $event->section_title // 'top', $event->percent );
		return;
	}
);

$ui->interaction->set_focused_widget($view);
$ui->run;
