;
 use strict;
 use warnings;
 use PDL;
 # Windows dynamic loading requires that Prima comes before PDL::Drawing::Prima
 use Prima qw(Application);
 use PDL::Drawing::Prima;
 
package My::Application;
our @ISA = qw(Prima::MainWindow);

sub color {
	print 'color got args [', join('], [', @_), "]\n";
	return $_[0]->SUPER::color($_[1]);
}

sub polyline {
	my $self = shift;
	print "polyline got args ", join(', ', @{$_[0]}), "\n";
	$self->SUPER::polyline(@_);
	print "Returning!\n";
}

sub fillpoly {
	my $self = shift;
	print "fillpoly got args ", join(', ', @{$_[0]}), "\n";
	$self->SUPER::fillpoly(@_);
	print "Returning!\n";
}

package main;

 my $window = My::Application->create(
     text    => 'PDL::Graphics::Prima Test',
     onPaint => sub {
         my ( $self, $canvas) = @_;
 
         # wipe and replot:
         $canvas->clear;
         
         ### Example code goes here ###
 use PDL::NiceSlice;
 
 # Draw a simple polyline
 my $x = sequence(50) * 10;
 my $y = 2 * $x + $x->grandom * 10;
 $canvas->pdl_polylines($x, $y);
 
 
 # Draw 50 shapes at random points:
 my ($width, $height) = $canvas->size;
 $x = random(50) * $width;
 $y = $x->random * $height;
 
 # Generate some fun random shapes and sizes:
 my $N_points = 1 + 9 * $x->random;
 my $orientation = $x->random * 360;
 my $filled = ($x->random < 0.5);
 my $size = 5 + 10 * $x->random;
 my $skip = ($x->random * $N_points)->byte;
 
 # Make a rainbow of colors:
 my $deg = $x->xlinvals(0, 360);
 my $hsv = ones(3, $x->nelem);
 $hsv(0, :) .= $deg->transpose;
 my $colors = $hsv->hsv_to_rgb->rgb_to_color;
 
 # Draw them:
 $canvas->pdl_symbols($x, $y, $N_points, $orientation, $filled, $size, $skip
	, colors => $colors);
         
     },
     backColor => cl::White,
 );
 
 run Prima;
