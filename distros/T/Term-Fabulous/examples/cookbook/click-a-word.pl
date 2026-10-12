#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Termbox qw(TB_KEY_MOUSE_LEFT TB_KEY_MOUSE_MIDDLE TB_KEY_MOUSE_RIGHT);
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::RichText;
use Term::Fabulous::Widget::Text;
use Clay::XS qw(sizing_grow sizing_fixed CLAY_TOP_TO_BOTTOM);

my %meaning_of = (
	cell     => 'one character position of the terminal',
	grapheme => 'what a reader sees as one character',
	span     => 'a range of a RichText with a look of its own',
	terminal => 'the program that shows this one',
	widget   => 'a part of the screen that draws itself',
);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

# A plain Text and a RichText, wrapped at 48 columns by the box around
# them. A click on either fires TextClick on it.
my $article = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_fixed(48) }, child_gap => 1 } );
$article->add_child(
	Term::Fabulous::Widget::Text->new( text => 'Every widget draws into the cells of the terminal. A wide grapheme takes two cells.' ),
	Term::Fabulous::Widget::RichText->new( markup => 'A [bold #e5c07b]span[/] changes the look of part of a text; the click reports the spans under the pointer.' ),
);

my $meaning = Term::Fabulous::Widget::Text->new( text => 'Left-click a word to look it up.',                       text_color => [ 152, 195, 121, 255 ] );
my $details = Term::Fabulous::Widget::Text->new( text => 'Right-click a character to see what the click reports.', text_color => [ 150, 160, 180, 255 ] );
$root->add_child( $article, $meaning, $details );

my %name_of_button = ( TB_KEY_MOUSE_LEFT() => 'left', TB_KEY_MOUSE_MIDDLE() => 'middle', TB_KEY_MOUSE_RIGHT() => 'right' );

sub look_up ($word) {
	my $key = lc( $word =~ s/[^\w]+//gr );    # "terminal." -> "terminal"
	my $meaning_text = $meaning_of{$key} // 'is not in the glossary';
	$meaning->text("$key: $meaning_text");
	return;
}

sub describe_click ($event) {
	my @styles = map { $_->[0] . '-' . $_->[1] } @{ $event->spans };
	$details->text(
		sprintf '%s button at column %d, row %d: offset %d, word %s (%s to %s), spans [%s]',
		$name_of_button{ $event->button },
		$event->x,                $event->y,                 $event->offset,
		$event->word // '(none)', $event->word_start // '-', $event->word_end // '-',
		join( ', ', @styles )
	);
	return;
}

# TextClick bubbles from the Text that was clicked to its ancestors, so
# one listener on the root hears every text.
$root->on(
	TextClick => sub ($event) {
		return describe_click($event) if $event->button == TB_KEY_MOUSE_RIGHT;
		return look_up( $event->word ) if defined $event->word;
		$meaning->text('That was a blank.');
		return;
	}
);

my $ui = Term::Fabulous->new( width => 80, height => 24, root => $root );
$root->on( KeyPress => sub ($event) { $ui->loop->stop if ( $event->key_name // '' ) eq 'Escape'; return } );
$ui->run;
