#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use Term::Fabulous;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Sixel;
use Term::Fabulous::Widget::Text;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM CLAY_ATTACH_TO_PARENT CLAY_ATTACH_POINT_CENTER_TOP);

# The picture to show: the first argument, or the example picture.
my $file = shift // "$FindBin::Bin/../images/mandelbrot.png";

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);
my $status = Term::Fabulous::Widget::Text->new( text => 'n, c, s: fit    h: help    q: quit', text_color => [ 150, 160, 180, 255 ] );

my $frame = Term::Fabulous::Widget::Box->new(
	bordered     => 1,
	border_style => Term::Fabulous::Enum::BorderStyle->Round,
	border_color => [ 120, 160, 220, 255 ],
	layout       => { sizing => { width => sizing_grow(), height => sizing_grow() } },
);
my $picture = Term::Fabulous::Widget::Sixel->new(
	file   => $file,
	fit    => 'contain',
	layout => { sizing => { width => sizing_grow(), height => sizing_grow() } },
);
$frame->add_child($picture);
$root->add_child( $status, $frame );

# The help floats over the top of the picture, which leaves those cells
# out.
my $help = Term::Fabulous::Widget::Box->new(
	layout           => { layout_direction => CLAY_TOP_TO_BOTTOM, padding => { left => 1, right => 1 } },
	background_color => [ 40, 44, 52, 255 ],
	bordered         => 1,
	border_color     => [ 229, 192, 123, 255 ],
	floating         => { attach_to => CLAY_ATTACH_TO_PARENT, attach_points => { element => CLAY_ATTACH_POINT_CENTER_TOP, parent => CLAY_ATTACH_POINT_CENTER_TOP } },
);
$help->add_child( map { Term::Fabulous::Widget::Text->new( text => $_ ) } 'n  natural size', 'c  contain', 's  stretch', 'h  this help' );

sub toggle_help () {
	$help->parent ? $frame->remove_child($help) : $frame->add_child($help);
	return;
}

my %fit_by_key = ( n => 'none', c => 'contain', s => 'stretch' );

my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );
$root->on(
	KeyPress => sub ($event) {
		my $key = $event->key_name // return;
		$ui->loop->stop if $key eq 'q';
		toggle_help() if $key eq 'h';
		my $fit = $fit_by_key{$key} or return;
		$picture->fit($fit);
		return;
	}
);
$ui->run;
