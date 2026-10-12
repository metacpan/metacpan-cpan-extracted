#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Text;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
	},
);
my $help = Term::Fabulous::Widget::Text->new( text => 'Try F1, Ctrl+R, Alt+Down, Ctrl+Shift+Left or any letter.', text_color => [ 230, 230, 230, 255 ] );
my $last = Term::Fabulous::Widget::Text->new( text => 'No key yet.',                                              text_color => [ 150, 200, 255, 255 ] );
$root->add_child( $help, $last );

my %action_by_key = (
	'F1'              => sub { $help->text('F1: this is the help.') },
	'Ctrl+R'          => sub { $help->text('Ctrl+R: reloaded.') },
	'Alt+Down'        => sub { $help->text('Alt+Down: moved down.') },
	'Ctrl+Shift+Left' => sub { $help->text('Ctrl+Shift+Left: selected a word to the left.') },
);

$root->on(
	KeyPress => sub ($event) {
		my $name = $event->key_name;
		my $text = $event->text;
		$last->text( sprintf 'key_name: %s, text: %s', $name // 'undef', defined $text ? "'$text'" : 'undef' );

		my $action = $action_by_key{ $name // '' } or return;
		$action->();
		return;
	}
);

Term::Fabulous->new( root => $root, width => 80, height => 24 )->run;
