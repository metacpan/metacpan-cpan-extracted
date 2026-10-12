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
		text       => 'Resize the terminal to rewrap the tags  (Ctrl+C to quit)',
		text_color => [ 220, 220, 220, 255 ],
	)
);

# Left to right, wrapping onto a new line whenever the next tag does not
# fit; lines are one row apart and keep the height of their tags.
my $tags = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_LEFT_TO_RIGHT_WRAP,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 1,             right  => 1 },
		child_gap        => 1,
		line_gap         => 1,
		line_sizing      => CLAY_LINE_SIZING_FIT,
	},
	background_color => [ 30, 35, 50, 255 ],
	bordered         => 1,
	border_color     => [ 120, 160, 220, 255 ],
	border_style     => Term::Fabulous::Enum::BorderStyle->Round,
);
$root->add_child($tags);

my @colors = ( [ 97, 175, 239, 255 ], [ 152, 195, 121, 255 ], [ 229, 192, 123, 255 ], [ 198, 120, 221, 255 ], [ 224, 108, 117, 255 ] );
my @words  = qw(perl terminal layout clay flow wrapping widgets unicode colors borders
	keyboard mouse focus scrolling canvas forms dialogs kdl static screenshots);

while ( my ( $index, $word ) = each @words ) {
	my $tag = Term::Fabulous::Widget::Box->new(
		layout           => { padding => { left => 1, right => 1 } },
		background_color => $colors[ $index % @colors ],
	);
	$tag->add_child(
		Term::Fabulous::Widget::Text->new(
			text       => $word,
			text_color => [ 20, 25, 35, 255 ],
		)
	);
	$tags->add_child($tag);
}

Term::Fabulous->new( width => 80, height => 24, root => $root )->run;
