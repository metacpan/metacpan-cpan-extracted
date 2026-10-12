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
		child_gap        => 1,
	},
);
$root->add_child(
	Term::Fabulous::Widget::Text->new(
		text       => 'Hello from Term::Fabulous! Press q, Escape or Ctrl+C to quit.',
		text_color => [ 230, 230, 230, 255 ],
	)
);

my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );

$root->on(
	KeyPress => sub ($event) {
		my $key = $event->key_name // return;
		$ui->loop->stop if $key eq 'q' || $key eq 'Escape';
		return;
	}
);

$ui->run;
