use strict;
use warnings;

use PDL;

# Get the M51 data file
my $PDL_full_file = $INC{'PDL.pm'};
(my $PDL_dir = $PDL_full_file) =~ s/\.pm$//;
use File::Spec;
my $M51_fn = File::Spec->catfile($PDL_dir, 'Demos', 'm51.fits');


#!/usr/bin/env perl

use strict;
use warnings;

use PDL;
use PDL::Image2D;
use PDL::Fit::Gaussian;
use Prima;
use PDL::Graphics::Prima::Simple;

my $file = $M51_fn;
analyze($file);

sub analyze {
  my $file = shift;

  my $pdl = rfits $file;
  my ($x_dim, $y_dim) = $pdl->dims;
  print "x_dim is $x_dim and y_dim is $y_dim\n";
  my ($val, $max_x, $max_y) = $pdl->max2d_ind;

  plot(
    -data => ds::Grid(
      $pdl,
      x_bounds => [1,$x_dim],
      y_bounds => [1,$y_dim],
      plotType => pgrid::Matrix(
        palette => pal::BlackToWhite,
      ),
    ),
    -max => ds::Pair(
      $max_x, $max_y,
      plotTypes => ppair::Crosses,
      colors => pdl(255, 0, 0)->rgb_to_color,
    ),
    onMouseClick => sub {
      my ($self, $button, undef, $x, $y) = @_;
      return unless $button & mb::Left;

      $x = int $self->x->pixels_to_reals($x);
      $y = int $self->y->pixels_to_reals($y); #-- #highlight fix

      xy_fit($pdl, $x, $y);

      $self->get_parent->close;
    },
    onKeyDown => sub {
     my ($self, $key) = @_;
     print join(', ', @_), "\n";
     return unless chr($key) eq "\n";

      xy_fit($pdl,$max_x,$max_y);
#      $self->get_parent->close;
    },
  );
}

sub xy_fit {
  my ($pdl, $x, $y) = @_;

  my $x_lineout = $pdl->slice(",($y)");
  my $y_lineout = $pdl->slice("($x),");

  my (undef, undef, $fwhm_x) = fitgauss1d(
    $x_lineout->sequence * 5.4,
    $x_lineout,
  );

  my (undef, undef, $fwhm_y) = fitgauss1d(
    $y_lineout->sequence * 5.4,
    $y_lineout,
  );

  print "X: $fwhm_x, Y: $fwhm_y\n";
  return ($fwhm_x, $fwhm_y);
}