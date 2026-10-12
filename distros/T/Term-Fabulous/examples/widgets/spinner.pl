#!/usr/bin/env perl

# Term::Fabulous::Widget::Spinner in every ready-made style, each with
# its name as the label: one-cell styles in the first column, wider and
# taller ones in the second, then a stopped spinner and one with frames
# of its own. They run on the application's clock, without timers.
# Ctrl+C quits.
#
#     perl examples/widgets/spinner.pl

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
use Term::Fabulous::Widget::Spinner;

use Clay::XS qw(sizing_grow sizing_fixed CLAY_TOP_TO_BOTTOM);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		sizing    => { width => sizing_grow(), height => sizing_grow() },
		padding   => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap => 4,
	},
);

sub column (@spinners) {
	my $column = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, child_gap => 1, sizing => { width => sizing_fixed(24) } } );
	$column->add_child(@spinners);
	return $column;
}

sub spinner ( $style, %more ) {
	return Term::Fabulous::Widget::Spinner->new( style => $style, label => $style, %more );
}

my %color = ( blue => [ 97, 175, 239, 255 ], green => [ 152, 195, 121, 255 ], yellow => [ 229, 192, 123, 255 ], red => [ 224, 108, 117, 255 ] );

$root->add_child(
	column( map { spinner($_) } qw(dots line arc circle arrow box pulse bar) ),
	column(
		spinner( 'dots3',  color => $color{green} ),
		spinner( 'bounce', color => $color{yellow} ),
		spinner( 'wave',   color => $color{red} ),
		spinner( 'ring',   color => $color{green} ),
		Term::Fabulous::Widget::Spinner->new( style  => 'line', label => 'stopped', running => 0 ),
		Term::Fabulous::Widget::Spinner->new( frames => [ map { ".oO\@Oo" =~ s/\A(.{$_})(.*)\z/$2$1/r } 0 .. 5 ], interval => 0.12, label => 'own frames', color => $color{yellow} ),
	),
);

my $ui = Term::Fabulous->new( width => 80, height => 24, root => $root );
$ui->run;
