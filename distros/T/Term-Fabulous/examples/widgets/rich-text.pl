#!/usr/bin/env perl

# Term::Fabulous::Widget::RichText: bold words, colored phrases and
# highlighted ranges inside one text, given as markup in the syntax of
# Python's rich library or as spans over the text, wrapped like any
# Text, and links to follow with a click or with Tab, Left/Right and
# Enter. Ctrl+C quits.
#
#     perl examples/widgets/rich-text.pl

use v5.32;
use warnings;
use strict;
use utf8;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../../lib/";

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::RichText;
use Term::Fabulous::Widget::Text;

use Clay::XS qw(sizing_grow sizing_fixed CLAY_TOP_TO_BOTTOM);

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

# Markup: tags open a style, [/] closes the innermost one.
state_row( 'markup', Term::Fabulous::Widget::RichText->new( markup => 'Press [bold]Enter[/] to save, [bold #e06c75]Esc[/] to leave. [dim]Unsaved changes are lost.[/]' ) );

# The same from spans: character offsets and a style string each.
my $log = Term::Fabulous::Widget::RichText->new( text => 'error: config.kdl not found (3 warnings)', spans => [ [ 0, 6, 'bold #e06c75' ] ] );
$log->stylize( 'underline',      7,  17 );    # the file name
$log->stylize( 'italic #d19a66', 28, 40 );    # the count
state_row( 'spans', $log );

state_row(
	'styles',
	Term::Fabulous::Widget::RichText->new(
		markup => '[bold]bold[/] [italic]italic[/] [underline]underline[/] [reverse]reverse[/] [dim]dim[/] [strike]strike[/] [overline]overline[/] [bold]bold [not bold]not bold[/][/]'
	)
);

# Spans run across the line breaks of a wrapped text.
my $panel = Term::Fabulous::Widget::Box->new( background_color => [ 30, 35, 50, 255 ], layout => { sizing => { width => sizing_fixed(34) }, padding => { left => 1, right => 1 } } );
$panel->add_child(
	Term::Fabulous::Widget::RichText->new(
		markup => 'A span is a range of the text with a look of its own: [italic #98c379]this one is italic and green, and it wraps with the text[/]; [on #3a3f4b]this one is highlighted[/] instead.',
	)
);
state_row( 'wrapped', $panel );

# Links: underlined in the accent color, highlighted under the mouse
# pointer and when selected. Following one fires LinkActivate; what the
# target means is up to the program.
my $links    = state_row( 'links',    Term::Fabulous::Widget::RichText->new( markup => 'Read the [link=faq]FAQ[/link], the [link=guide]guide[/link] or [link=https://perl.org]perl.org[/link].' ) );
my $followed = state_row( 'followed', Term::Fabulous::Widget::Text->new( text => 'Tab selects a link, Left and Right move, Enter follows it.' ) );
$links->on( LinkActivate => sub ($event) { $followed->text( 'You followed the link to ' . $event->link . '.' ); return } );

Term::Fabulous->new( width => 80, height => 24, root => $root )->run;
