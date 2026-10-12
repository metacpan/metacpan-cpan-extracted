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

my @styles  = Term::Fabulous::Enum::BorderStyle->values;
my $columns = 4;

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

my $title = Term::Fabulous::Widget::Text->new(
	text       => 'Term::Fabulous border styles  (Ctrl+C to quit)',
	text_color => [ 220, 220, 220, 255 ],
);
$root->add_child($title);

my $row;
for my $i ( 0 .. $#styles ) {
	if ( $i % $columns == 0 ) {
		$row = Term::Fabulous::Widget::Box->new(
			layout => {
				sizing    => { width => sizing_grow(), height => sizing_grow() },
				child_gap => 2,
			},
		);
		$root->add_child($row);
	}

	my $style = $styles[$i];

	my $cell = Term::Fabulous::Widget::Box->new(
		layout => {
			layout_direction => CLAY_TOP_TO_BOTTOM,
			sizing           => { width => sizing_grow(), height => sizing_grow() },
			padding          => { left  => 1, right => 1, top => 1, bottom => 1 },
		},
		background_color => [ 35,  40,  55,  255 ],
		border_color     => [ 180, 200, 220, 255 ],
		bordered         => 1,
		border_style     => $style,
	);

	my $label = Term::Fabulous::Widget::Text->new(
		text       => $style->name,
		text_color => [ 255, 255, 255, 255 ],
	);

	$cell->add_child($label);
	$row->add_child($cell);
}

my $ui = Term::Fabulous->new(
	width  => 100,
	height => 32,
	root   => $root,
);

$ui->run();
