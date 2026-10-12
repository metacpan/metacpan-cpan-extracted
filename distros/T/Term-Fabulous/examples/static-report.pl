#!/usr/bin/env perl

# Renders a widget tree once, to STDOUT, without opening the terminal:
# colored when STDOUT is a terminal, plain text when it is a pipe.
#
#     perl examples/static-report.pl
#     perl examples/static-report.pl | cat

use v5.32;
use warnings;
use utf8;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../lib/";

use Term::Fabulous::Static;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Enum::BorderStyle;

use Clay::XS qw(:all);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_fit() },
		child_gap        => 1,
	},
);

my %panels = (
	'Round'  => "Grüße vom Oktoberfest\nSpaß mit Umlauten äöüß",
	'Heavy'  => "いろはにほへと\nちりぬるを",
	'Double' => "Every panel is a Box with a border style;\nthe lines are Text widgets.",
);

foreach my $style ( sort keys %panels ) {
	my $panel = Term::Fabulous::Widget::Box->new(
		layout => {
			layout_direction => CLAY_TOP_TO_BOTTOM,
			sizing           => { width => sizing_grow(), height => sizing_fit() },
			padding          => { left  => 1,             right  => 1 },
		},
		bordered     => 1,
		border_style => Term::Fabulous::Enum::BorderStyle->from_name($style),
		border_color => [ 120, 180, 240, 255 ],
	);
	$panel->add_child( Term::Fabulous::Widget::Text->new( text => "$style border", text_color => [ 255, 200, 80, 255 ] ) );
	$panel->add_child( Term::Fabulous::Widget::Text->new( text => $_, text_color => [ 230, 230, 230, 255 ] ) ) foreach split /\n/, $panels{$style};
	$root->add_child($panel);
}

Term::Fabulous::Static->new( root => $root, width => 60 )->print;
