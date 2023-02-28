 use strict;
 use warnings;
 use PDL;
 # Windows dynamic loading requires that Prima comes before PDL::Drawing::Prima
 use Prima qw(Application);
 use PDL::Drawing::Prima;
 
 my $window = Prima::MainWindow->create(
     text    => 'PDL::Graphics::Prima Test',
     fillWinding => 1,
     onPaint => sub {
         my ( $self, $canvas) = @_;
 
         # wipe and replot:
         $canvas->clear;
         
         ### Example code goes here ###
 use PDL::NiceSlice;
 
 # Generate a table of shapes:
 my @dims = (20, 2, 20);
 my $N_points = xvals(@dims)->clump(2);
 my $orientation = 0;
 my $filled = yvals(@dims)->clump(2);
 my $size = 10;
 my $skip = zvals(@dims)->clump(2);
 my $x = $N_points->xvals * 25 + 25;
 my $y = $N_points->yvals * 25 + 25;
 my $lineWidths = $ARGV[0] || 1;
 # Test bad-value handling:
 $N_points->setbadat(20, 15);
 
 # Draw them:
 $canvas->pdl_symbols($x, $y, $N_points, 0, $filled, 10, $skip
    , lineWidths => $lineWidths);
         
     },
     backColor => cl::White,
 );
 
 run Prima;
