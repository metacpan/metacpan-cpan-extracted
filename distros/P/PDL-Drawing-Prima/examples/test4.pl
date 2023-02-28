;
 use strict;
 use warnings;
 use PDL;
 # Windows dynamic loading requires that Prima comes before PDL::Drawing::Prima
 use Prima qw(Application);
 use PDL::Drawing::Prima;
 
 my $window = Prima::MainWindow->create(
     text    => 'PDL::Graphics::Prima Test',
     onPaint => sub {
         my ( $self, $canvas) = @_;
 
         # wipe and replot:
         $canvas->clear;
         
         ### Example code goes here ###
 use PDL::NiceSlice;
 
 # Draw 50 shapes at random points:
 my ($width, $height) = $canvas->size;
 my $x = random(50) * $width;
 my $y = $x->random * $height;
 
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
