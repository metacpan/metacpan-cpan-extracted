#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous::Static;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Text;
use Clay::XS qw(CLAY_TOP_TO_BOTTOM);

sub text ($string) {
	return Term::Fabulous::Widget::Text->new( text => $string, text_color => [ 230, 230, 230, 255 ] );
}

my $root = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM } );
$root->add_child(
	text("Gr\x{fc}\x{df}e aus M\x{fc}nchen"),    # German umlauts and sharp s
	text("\x{3044}\x{308d}\x{306f}\x{306b}\x{307b}\x{3078}\x{3068}|"),    # Japanese, two columns each
	text("e\x{301} is one character|"),    # e and a combining acute accent
);

Term::Fabulous::Static->new( root => $root, width => 30 )->print( colors => 0 );
