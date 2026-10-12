#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use Term::Fabulous;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Image;
use Term::Fabulous::Widget::Text;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

# The picture to show: the first argument, or the example picture.
my $file = shift // "$FindBin::Bin/../images/translucent_circles.png";

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);
my $header = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM } );
my $status = Term::Fabulous::Widget::Text->new( text_color => [ 230, 230, 230, 255 ] );
$header->add_child( $status, Term::Fabulous::Widget::Text->new( text => 'n, c, s: fit    b: background    q: quit', text_color => [ 150, 160, 180, 255 ] ) );

# The picture fills a frame; its background is the area inside the frame.
my $frame = Term::Fabulous::Widget::Box->new(
	bordered     => 1,
	border_style => Term::Fabulous::Enum::BorderStyle->Round,
	border_color => [ 120, 160, 220, 255 ],
	layout       => { sizing => { width => sizing_grow(), height => sizing_grow() } },
);
my $picture = Term::Fabulous::Widget::Image->new(
	file   => $file,
	fit    => 'contain',
	layout => { sizing => { width => sizing_grow(), height => sizing_grow() } },
);
$frame->add_child($picture);
$root->add_child( $header, $frame );

sub show_status () {
	my $size = defined $picture->image_width ? $picture->image_width . 'x' . $picture->image_height : 'unknown size';
	$status->text( sprintf '%s  %s  fit: %s', $file =~ s{.*/}{}r, $size, $picture->fit );
	return;
}
show_status();

my %fit_by_key = ( n => 'none', c => 'contain', s => 'stretch' );

# b switches between the screen's background and a white one: the
# transparent parts of the picture show it, the translucent ones are
# mixed with it.
my $white = 0;

sub toggle_background () {
	$white = !$white;
	$picture->background_color( $white ? [ 255, 255, 255, 255 ] : undef );
	return;
}

my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );
$root->on(
	KeyPress => sub ($event) {
		my $key = $event->key_name // return;
		$ui->loop->stop if $key eq 'q';
		toggle_background() if $key eq 'b';
		my $fit = $fit_by_key{$key} or return;
		$picture->fit($fit);
		show_status();
		return;
	}
);
$ui->run;
