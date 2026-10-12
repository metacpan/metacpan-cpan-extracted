#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Clay::XS qw(sizing_grow CLAY_ALIGN_X_CENTER CLAY_ALIGN_Y_CENTER);
use Term::Fabulous;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Text;

# The root widget fills the whole terminal and centers its child.
my $root = Term::Fabulous::Widget::Box->new(
	background_color => [ 20, 25, 45, 255 ],
	layout           => {
		sizing          => { width => sizing_grow(),       height => sizing_grow() },
		child_alignment => { x     => CLAY_ALIGN_X_CENTER, y      => CLAY_ALIGN_Y_CENTER },
	},
);

# A box with a rounded border, one cell of space left and right of the text.
my $frame = Term::Fabulous::Widget::Box->new(
	bordered     => 1,
	border_style => Term::Fabulous::Enum::BorderStyle->Round,
	border_color => [ 120, 170, 255, 255 ],
	layout       => { padding => { left => 1, right => 1 } },
);
$frame->add_child(
	Term::Fabulous::Widget::Text->new(
		text       => 'Hello, terminal! Press q to quit.',
		text_color => [ 255, 255, 255, 255 ],
	)
);
$root->add_child($frame);

my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );

# Nothing has the keyboard focus, so key presses go to the root widget.
$root->on(
	KeyPress => sub ($event) {
		my $name = $event->key_name // '';
		$ui->loop->stop if $name eq 'q' || $name eq 'Escape';
		return;
	}
);

$ui->run;    # returns when the loop stops
say 'Bye!';
