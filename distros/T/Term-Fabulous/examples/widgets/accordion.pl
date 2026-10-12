#!/usr/bin/env perl

# Term::Fabulous::Widget::Accordion: a settings accordion with one
# section open at a time and a disabled section, and one with a border
# around every item, the toggles at the end of the headers and several
# sections open at once. Tab moves the focus, Up and Down move between
# the headers, Enter or Space opens and closes the focused section, so
# does a click, Ctrl+C quits.
#
#     perl examples/widgets/accordion.pl

use v5.32;
use warnings;
use strict;
use utf8;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../../lib/";

use Term::Fabulous;
use Term::Fabulous::Widget::Accordion;
use Term::Fabulous::Widget::Accordion::Item;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Checkbox;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::TextField;

use Clay::XS qw(sizing_grow sizing_fixed CLAY_TOP_TO_BOTTOM);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		sizing    => { width => sizing_grow(), height => sizing_grow() },
		padding   => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap => 3,
	},
);

sub text ( $string, $color = [ 200, 205, 215, 255 ] ) {
	return Term::Fabulous::Widget::Text->new( text => $string, text_color => $color );
}

sub row ( $label, $input ) {
	my $row = Term::Fabulous::Widget::Box->new( layout => { child_gap => 1 } );
	$row->add_child( text($label), $input );
	return $row;
}

sub item ( $title, @body ) {
	my $item = Term::Fabulous::Widget::Accordion::Item->new( title => $title );
	$item->add_child(@body);
	return $item;
}

# One section at a time; the third cannot be opened.
my $settings = Term::Fabulous::Widget::Accordion->new( layout => { sizing => { width => sizing_fixed(34) } }, title_bold => 1 );
$settings->add_child(
	item(
		'General', row( 'Language ', Term::Fabulous::Widget::TextField->new( value => 'en', preferred_columns => 8 ) ),
		Term::Fabulous::Widget::Checkbox->new( label => 'Check for updates', checked => 1 )
	),
	item(
		'Network', row( 'Hostname ', Term::Fabulous::Widget::TextField->new( value => 'example.org', preferred_columns => 14 ) ),
		row( 'Port     ', Term::Fabulous::Widget::TextField->new( value => '443', preferred_columns => 6 ) )
	),
	item( 'Users',    text('Three accounts, two groups.') ),
	item( 'Licenses', text('Not available in this edition.') ),
);
$settings->item(3)->disabled(1);
$settings->open(1);

# Several at once, a border around every item, the toggles at the end.
my $faq = Term::Fabulous::Widget::Accordion->new(
	layout          => { sizing => { width => sizing_fixed(38) }, child_gap => 1 },
	multiple        => 1,
	item_borders    => 1,
	toggle_position => 'end',
	open_glyph      => '-',
	closed_glyph    => '+',
);
$faq->add_child(
	item( 'What is Term::Fabulous?', text('A toolkit for terminal user interfaces in Perl.') ),
	item( 'Does the mouse work?',    text('Yes: clicks, drags, the wheel and hover.') ),
	item( 'Can I use KDL?',          text('Every widget can be built from a layout file.') ),
);
$faq->open(0);
$faq->open(2);

$root->add_child( $settings, $faq );

my $ui = Term::Fabulous->new( width => 80, height => 24, root => $root );
$ui->interaction->set_focused_widget( $settings->item(1)->header );
$ui->run;
