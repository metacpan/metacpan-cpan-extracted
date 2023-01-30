#!/usr/bin/env perl
#
# Mandelbrot generation function is courtesy of Xavier Calbet
# from http://www.freesoftwaremagazine.com/articles/cool_fractals_with_perl_pdl_a_benchmark
#

# PDL code to navigate a Mandelbrot fractal

use strict;
use warnings;
use PDL; 
use Prima qw(Application);
use PDL::PrimaImage;
use PDL::Graphics::LUT;
use PDL::NiceSlice;
use Time::HiRes qw(time);


# Number of points in side of image and
# number of iterations in the Mandelbrot
# fractal calculation
my $npts=512;
my $niter=16;

my @x = (-1.5, 0.5);
my @y = (-1, 1);
my $dzoom = 0.1;
my $w;
my $t;
my $speed = 0.001;
my $direction = 1;
my $status = '';
my $lut;
my $current;

sub generate
{
	my ($x1,$x2,$y1,$y2) = @_;

	return if $npts < 4;

	my $t0 = time;

	# Generating z = 0 (real and
	# imaginary part)
	my $zRe=zeroes(double,$npts,$npts);
	my $zIm=zeroes(double,$npts,$npts);

	# Generating the constant k (real and
	# imaginary part)
	my $kRe=$zRe->xlinvals($x1,$x2);
	my $kIm=$zIm->ylinvals($y1,$y2);
		
	# Iterating 
	for(my $j=0;$j<$niter;$j++){
	    # Calculating q = z*z + k in complex space
	    # q is a temporary variable to store the result
	    my $qRe=$zRe*$zRe-$zIm*$zIm+$kRe;
	    my $qIm=2*$zRe*$zIm+$kIm;
	    # Assigning the q values to z constraining between
	    # -5 and 5 to avoid numerical divergences
	    $zRe=$qRe->clip(-5,5);
	    $zIm=$qIm->clip(-5,5);
	}
	
	# Generating the image to plot
	my $image=log( sqrt($zRe**2+$zIm**2) + 1);
	my $i = PDL::PrimaImage::image( $image);
	$i->resample($i->rangeLo,$i->rangeHi,0,255);
	$i->type(im::Byte);
	if ( $lut ) {
		$i->type(im::bpp8);
		$i->palette($lut);
	}

	$t0 = time - $t0;
	if ( $t && $t->get_active ) {
		$status = 
			( $direction ? '>' : '<' ) .
			sprintf("%.1ffps x=%.2f", 1/$t0, 1000*$speed);
	} else {
		$status = sprintf("%.2fs", $t0);
	}
	$status .= sprintf(" q=$niter z=%.3e", $x[1]-$x[0]);

	return $i;
}

sub regenerate
{
	$current = generate(@x,@y);
	$w->repaint if $w;
}

sub replot
{
	my ( $x, $y, $btn, $zoom ) = @_;
	my $d = $x[1] - $x[0];
	for (0,1) {
		$x[$_] += ($x/$npts-.5) * $d;
		$y[$_] += ($y/$npts-.5) * $d;
	}
	$d = $zoom * $d * (($btn == mb::Left) ? 1 : -1);
	$x[0] += $d;
	$x[1] -= $d;
	$y[0] += $d;
	$y[1] -= $d;
	regenerate;
}

sub lut
{
	my $name = shift;
	unless ( defined $name ) {
		$lut = undef;
		regenerate;
		return;
	}
	my ( $l, $r, $g, $b ) = lut_data($name);
	$r *= 255;
	$g *= 255;
	$b *= 255;
	$lut = [ map { $b->at($_), $g->at($_), $r->at($_) } 0..255 ];
	regenerate;
}

lut('smooth');
$w = Prima::MainWindow->new(
	size => [ $npts, $npts ],
	text => 'Mandelbrot',
	buffered => 1,
	menuItems => [
		['~Options' => [
			[ '~Start/stop' => 'Space' => kb::Space, sub { $t->get_active ? $t->stop : $t->start } ],
			[ '~Forward/backward' => 'Backspace' => kb::Backspace, sub { $direction = !$direction } ],
			[ 'Speed ~up'   => 'Up'    => kb::Up, sub { $speed *= 1.2 } ],
			[ 'Speed ~down' => 'Down'  => kb::Down, sub { $speed /= 1.2 } ],
			[ 'Quality ~down' => 'Left'  => kb::Left, sub { $niter--, regenerate if $niter > 2    } ],
			[ 'Quality ~up' => 'Right'  => kb::Right, sub { $niter++, regenerate if $niter < 1000 } ],
			[ '~Reset' => '0'          => 0, sub {
				$t->stop;
				$speed = 0.001;
				$direction = 1;
				@x = (-1.5, 0.5);
				@y = (-1, 1);
				regenerate;
			} ],
			[ '*ts' => 'Show stat~us' => sub { $_[0]->menu->toggle($_[1]); $_[0]->repaint } ],
		]],
		['~Colors' => [
			['Default ~grayscale' => sub { lut(undef) }],
			map { my $k = $_; [ $k, sub { lut($k) } ] } lut_names,
		]],
	],
	onPaint => sub {
		my $self = shift;
		$self->clear;
		$self->put_image(0,0,$current) if $current;
		if ( $self->menu->ts->checked ) {
			$self->color(cl::LightGreen);
			$self->text_out( $status, 5, $self->height - $self->font->height - 5);
		}
	},
	onMouseDown => sub {
		my ($self, $btn, $mod, $x, $y) = @_;
		replot($x,$y,$btn,$dzoom);
	},
	onMouseClick => sub {
		my ($self, $btn, $mod, $x, $y, $dbl) = @_;
		replot($x,$y,$btn,$dzoom) if $dbl;
	},
	onMouseWheel => sub {
		my ($self, $mod, $x, $y, $z) = @_;
		replot($x,$y,($z < 0) ? mb::Left : mb::Right, $dzoom);
	},
	onSize => sub {
		my ( $self, $ox, $oy, $x, $y ) = @_;
		$npts = ( $x < $y ) ? $x : $y;
		regenerate;
	},
);

$t = $w->insert( Timer => 
	timeout => 50,
	onTick  => sub {
		my ($x,$y) = $w->pointerPos;
		my $c = $npts/2;
		$x -= $c;
		$y -= $c;
		$x /= 10;
		$y /= 10;
		my $box = 5;
		$x = -$box if $x < -$box;
		$y = -$box if $y < -$box;
		$x = $box if $x > $box;
		$y = $box if $y > $box;
		$x += $c;
		$y += $c;
		replot($x,$y, $direction ? mb::Left : mb::Right, $speed);
	},
);
$t->start;

$w->pointerPos( $npts/2, $npts/2);

run Prima;
