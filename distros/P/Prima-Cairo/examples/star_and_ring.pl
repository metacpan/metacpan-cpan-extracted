# This a Perl port of the C example cairo-demo/png/star_and_ring.c.  Original
# copyright:
# Copyright © 2005 Red Hat, Inc.

use strict;
use warnings;
use Prima qw(Application Cairo);

sub ring_path {
  my ($cr,$x,$y) = @_;
  $cr->move_to (200.86568, 667.80795);
  $cr->curve_to (110.32266, 562.62134,
                 122.22863, 403.77940,
                 227.41524, 313.23637);
  $cr->curve_to (332.60185, 222.69334,
                 491.42341, 234.57563,
                 581.96644, 339.76224);
  $cr->curve_to (672.50948, 444.94884,
                 660.64756, 603.79410,
                 555.46095, 694.33712);
  $cr->curve_to (450.27436, 784.88016,
                 291.40871, 772.99456,
                 200.86568, 667.80795);
  $cr->close_path;

  $cr->move_to (272.14411, 365.19927);
  $cr->curve_to (195.64476, 431.04875,
                 186.97911, 546.57972,
                 252.82859, 623.07908);
  $cr->curve_to (318.67807, 699.57844,
                 434.23272, 708.22370,
                 510.73208, 642.37422);
  $cr->curve_to (587.23144, 576.52474,
                 595.85301, 460.99047,
                 530.00354, 384.49112);
  $cr->curve_to (464.15406, 307.99176,
                 348.64347, 299.34979,
                 272.14411, 365.19927);
  $cr->close_path;
}

sub star_path {
  my ($cr) = @_;

  my $matrix = Cairo::Matrix->init (0.647919, -0.761710,
                                    0.761710, 0.647919,
                                    -208.7977, 462.0608);
  $cr->transform ($matrix);

  $cr->move_to (505.80857, 746.23606);
  $cr->line_to (335.06870, 555.86488);
  $cr->line_to (91.840384, 635.31360);
  $cr->line_to (282.21157, 464.57374);
  $cr->line_to (202.76285, 221.34542);
  $cr->line_to (373.50271, 411.71660);
  $cr->line_to (616.73103, 332.26788);
  $cr->line_to (426.35984, 503.00775);
  $cr->line_to (505.80857, 746.23606);
  $cr->close_path;
}

sub fill_ring {
  my ($cr) = @_;

  $cr->save;
  $cr->translate (-90, -205);
  ring_path ($cr);
  $cr->set_source_rgba (1.0, 0.0, 0.0, 0.75);
  $cr->fill;
  $cr->restore;
}

sub fill_star {
  my ($cr) = @_;

  $cr->save;
  $cr->translate (-90, -205);
  star_path ($cr);
  $cr->set_source_rgba (0.0, 0.0, 0xae / 0xff, 0.55135137);
  $cr->fill;
  $cr->restore;
}

my $alpha = 0;
my $w = Prima::MainWindow->new(
	layered => 1,
	buffered => 1,
	text => 'Cairo - star & ring',
	size => [300,300],
	backColor => 0,
	onMouseDown  => sub { shift->{grab} = 1 },
	onMouseUp    => sub { shift->{grab} = 0 },
	onPaint => sub {
		my ( $self, $canvas ) = @_;
		$self->clear;
		my @size = $self->size;
                my $cr = $canvas->cairo_context( transform => 0 );
		$cr->scale($size[0]/600,$size[1]/600);
  		$cr->translate ( 300, 300 );
		if ( $self-> {grab} ) {
			my ( $x, $y ) = $self-> pointerPos;
			$x -= $size[0]/2;
			$y -= $size[1]/2;
			$alpha = atan2($x, $y);
		}
		$cr->rotate( $alpha );
  		$cr->translate ( -300, -300);

    		fill_star($cr);
    		fill_ring($cr);
	}
);

$w-> insert( Timer => 
	timeout => 5,
	onTick  => sub {
		$alpha += 0.001;
		$alpha = 0 if $alpha > 6.28;
		$w-> repaint;
	}
)-> start;
run Prima;
