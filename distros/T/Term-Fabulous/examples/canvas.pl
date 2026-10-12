#!/usr/bin/env perl

use v5.32;
use warnings;
use strict;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../lib/";

use IO::Async::Loop;
use IO::Async::Timer::Periodic;
use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Canvas;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Enum::BorderStyle;

use Clay::XS qw(:all);

use constant UPPER_HALF => "\x{2580}";
use constant LOWER_HALF => "\x{2584}";

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
		text       => 'Three waves plotted with half blocks; only moved pixels are redrawn  (Ctrl+C to quit)',
		text_color => [ 220, 220, 220, 255 ],
	)
);

my $canvas = Term::Fabulous::Widget::Canvas->new(
	background_color => [ 10, 12, 20, 255 ],
	bordered         => 1,
	border_color     => [ 120, 160, 220, 255 ],
	border_style     => Term::Fabulous::Enum::BorderStyle->Round,
	layout           => { sizing => { width => sizing_grow(), height => sizing_grow() } },
);
$root->add_child($canvas);

# Every cell shows two pixels stacked on top of each other: the upper half
# block in the foreground color over the background color.
my @pixel_color;    # [x][pixel_y]

sub paint_cell ( $x, $y ) {
	my ( $top, $bottom ) = ( $pixel_color[$x][ 2 * $y ], $pixel_color[$x][ 2 * $y + 1 ] );
	return $canvas->erase( $x, $y ) if !defined $top && !defined $bottom;
	return $canvas->put( $x, $y, LOWER_HALF, $bottom ) if !defined $top;
	return $canvas->put( $x, $y, UPPER_HALF, $top, $bottom );
}

my @waves = (
	{ color => 0xFF6E6E, speed =>  1.2, length => 9 },
	{ color => 0x6EC8FF, speed => -0.7, length => 14 },
	{ color => 0x22FFC8, speed =>  0.1, length => 19 },
);
my @lit_rows;    # [x] => the pixel row of every wave in that column
my $phase = 0;

# Repaints only the cells whose pixels moved; where the waves cross, the
# later wave wins.
sub plot () {
	my $pixel_rows = 2 * $canvas->rows;
	return unless $pixel_rows;
	foreach my $x ( 0 .. $canvas->columns - 1 ) {
		my @old = @{ $lit_rows[$x] // [] };
		my @new = map { int( ( sin( $x / $_->{length} + $phase * $_->{speed} ) + 1 ) / 2 * ( $pixel_rows - 1 ) + 0.5 ) } @waves;
		next if "@old" eq "@new";

		$pixel_color[$x][$_]         = undef foreach @old;
		$pixel_color[$x][ $new[$_] ] = $waves[$_]{color} foreach 0 .. $#waves;
		$lit_rows[$x]                = \@new;
		my %cell_rows = map { int( $_ / 2 ) => 1 } @old, @new;
		paint_cell( $x, $_ ) foreach keys %cell_rows;
	}
	return;
}

$canvas->on(
	CanvasResize => sub ($event) {
		@pixel_color = ();
		@lit_rows    = ();
		$canvas->clear;
		plot();
		return;
	}
);

my $ui = Term::Fabulous->new( width => 80, height => 24, root => $root );

my $animation = IO::Async::Timer::Periodic->new(
	interval => 1 / 30,
	on_tick  => sub { $phase += 0.1; plot(); return },
);
$animation->start;
IO::Async::Loop->new->add($animation);

$ui->run;
