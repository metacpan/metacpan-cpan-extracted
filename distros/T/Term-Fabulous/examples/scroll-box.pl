#!/usr/bin/env perl

use v5.32;
use warnings;
use strict;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../lib/";

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::ScrollBox;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Enum::BorderStyle;

use Clay::XS qw(:all);

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
		text       => 'Scroll the boxes with the mouse wheel  (Ctrl+C to quit)',
		text_color => [ 220, 220, 220, 255 ],
	)
);

my $panels = Term::Fabulous::Widget::Box->new(
	layout => {
		sizing    => { width => sizing_grow(), height => sizing_grow() },
		child_gap => 2,
	},
);
$root->add_child($panels);

for my $panel ( [ 'numbers', 200, sub ($n) { sprintf 'Line %3d', $n } ], [ 'squares', 60, sub ($n) { sprintf '%2d^2 = %4d', $n, $n * $n } ] ) {
	my ( $id, $count, $format ) = @$panel;
	my $box = Term::Fabulous::Widget::ScrollBox->new(
		id     => $id,
		layout => {
			layout_direction => CLAY_TOP_TO_BOTTOM,
			sizing           => { width => sizing_grow(), height => sizing_grow() },
			padding          => { left  => 1,             right  => 1 },
		},
		background_color => [ 30, 35, 50, 255 ],
		bordered         => 1,
		border_color     => [ 120, 160, 220, 255 ],
		border_style     => Term::Fabulous::Enum::BorderStyle->Round,
	);
	$box->add_child(
		Term::Fabulous::Widget::Text->new(
			text       => $format->($_),
			text_color => [ 200, 210, 230, 255 ],
		)
	) for 1 .. $count;
	$panels->add_child($box);
}

Term::Fabulous->new( width => 80, height => 24, root => $root )->run;
