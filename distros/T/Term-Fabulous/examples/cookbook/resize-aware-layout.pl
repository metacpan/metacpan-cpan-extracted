#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use IO::Async::Loop;
use Term::Fabulous;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Text;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM CLAY_LEFT_TO_RIGHT);

use constant NARROW_COLUMNS => 70;

my $root = Term::Fabulous::Widget::Box->new(
	layout => { sizing => { width => sizing_grow(), height => sizing_grow() }, child_gap => 1 },
);
foreach my $name (qw(Inbox Message)) {
	my $pane = Term::Fabulous::Widget::Box->new(
		bordered     => 1,
		border_style => Term::Fabulous::Enum::BorderStyle->Round,
		border_color => [ 120, 160, 220, 255 ],
		layout       => { sizing => { width => sizing_grow(), height => sizing_grow() }, padding => { left => 1 } },
	);
	$pane->add_child( Term::Fabulous::Widget::Text->new( text => $name, text_color => [ 230, 230, 230, 255 ] ) );
	$root->add_child($pane);
}

# Panes side by side on a wide terminal, stacked on a narrow one.
sub arrange ($columns) {
	my $direction = $columns < NARROW_COLUMNS ? CLAY_TOP_TO_BOTTOM : CLAY_LEFT_TO_RIGHT;
	$root->layout( { %{ $root->layout }, layout_direction => $direction } );
	return;
}

# Start is fired on the root once, when run() has opened the terminal
# and knows its size. Resize is fired twice per resize: before the new
# size is applied (is_pre_event) and after it (is_post_event).
$root->on( Start => sub ($event) { arrange( $event->width ); return } );
$root->on(
	Resize => sub ($event) {
		arrange( $event->width ) if $event->is_post_event;
		return;
	}
);

my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );
$ui->run;
