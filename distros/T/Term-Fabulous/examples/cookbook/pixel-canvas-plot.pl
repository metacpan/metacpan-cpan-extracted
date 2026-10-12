#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::PixelCanvas;
use Term::Fabulous::Widget::Text;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

# Some data: one value per pixel column is plotted, so any number of
# points works.
my @temperatures = map { 12 + 8 * sin( $_ / 9 ) + 3 * sin( $_ / 2.3 ) } 0 .. 199;

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);
$root->add_child( Term::Fabulous::Widget::Text->new( text => 'Temperature over 200 hours', text_color => [ 230, 230, 230, 255 ] ) );

my $plot = Term::Fabulous::Widget::PixelCanvas->new(
	background_color => [ 10, 12, 20, 255 ],
	bordered         => 1,
	border_style     => Term::Fabulous::Enum::BorderStyle->Round,
	border_color     => [ 120, 160, 220, 255 ],
	layout           => { sizing => { width => sizing_grow(), height => sizing_grow() } },
);
$root->add_child($plot);

# The pixel size is known only once the layout has sized the canvas, and
# it changes with the terminal: draw whenever it is (re)sized.
$plot->on(
	CanvasResize => sub ($event) {
		my ( $width, $height ) = ( $plot->pixel_width, $plot->pixel_height );
		return if $width < 2 || $height < 2;
		my ( $low, $high ) = ( -5, 30 );
		my $y_of = sub ($value) { ( $height - 1 ) * ( $high - $value ) / ( $high - $low ) };

		$plot->clear;
		$plot->draw_line( 0, $y_of->(0), $width - 1, $y_of->(0), 0x404860 );    # the zero line

		my $previous;
		foreach my $x ( 0 .. $width - 1 ) {
			my $value = $temperatures[ int( $x * @temperatures / $width ) ];
			my @point = ( $x, $y_of->($value) );
			$plot->draw_line( @$previous, @point, $value > 20 ? '#ff6e6e' : '#6ec8ff' ) if $previous;
			$previous = \@point;
		}
		$plot->put_text( 1, 0,               "$high C", 0x9098B0 );
		$plot->put_text( 1, $plot->rows - 1, "$low C",  0x9098B0 );
		return;
	}
);

Term::Fabulous->new( root => $root, width => 80, height => 24 )->run;
