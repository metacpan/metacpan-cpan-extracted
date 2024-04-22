# Demo x08 for the PLplot PDL binding
#
# 3-d plot demo
#
# Copyright (C) 2004  Rafael Laboissiere
#
# This file is part of PLplot.
#
# PLplot is free software; you can redistribute it and/or modify
# it under the terms of the GNU Library General Public License as published
# by the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# PLplot is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public License
# along with PLplot; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA

# SYNC: x08c.c 1.45

use strict;
use warnings;
use PDL;
use PDL::Graphics::PLplot;
use Math::Trig qw [pi];

use Getopt::Long;

use constant XPTS => 35;    # Data points in x
use constant YPTS => 45;    # Data points in y

use constant LEVELS => 10;

my @alt = (60.0, 40.0);
my @az = (30.0, -30.0);

my @title = (
  "#frPLplot Example 8 - Alt=60, Az=30",
  "#frPLplot Example 8 - Alt=40, Az=-30"
);

sub cmap1_init {
  my $gray = shift;

  my ($i, $h, $l, $s);

  $i = pdl [0.0,    # left boundary
            1.0];   # right boundary

  if ($gray) {
    $h = pdl [0.0,    # hue -- low: red (arbitrary if s=0)
              0.0];   # hue -- high: red (arbitrary if s=0)

    $l = pdl [0.5,    # lightness -- low: half-dark
              1.0];   # lightness -- high: light

    $s = pdl [0.0,    # minimum saturation
              0.0];   # minimum saturation
  } else {
    ($h, $l, $s) = (pdl(240, 0), pdl(0.6, 0.6), pdl(0.8, 0.8));
  }

  plscmap1n (256);
  plscmap1l (0, $i, $h, $l, $s, pdl []);
}

# Parse and process command line arguments
my $rosen;
plParseOpts (\@ARGV, PL_PARSE_SKIP | PL_PARSE_NOPROGRAM);
GetOptions ("rosen" => \$rosen);

my ($indexxmin, $indexxmax) = (0, XPTS);
# parameters of ellipse (in x, y index coordinates) that limits the data.
# x0, y0 correspond to the exact floating point centre of the index range.
my ($x0, $y0) = (0.5 * ( XPTS - 1 ), 0.5 * ( YPTS - 1 ));
my ($a, $b) = (0.9 * $x0, 0.7 * $y0);

# Initialize plplot
plinit ();

my ($x, $y) = map +(sequence($_) - int($_ / 2)) / int($_ / 2), XPTS, YPTS;
$x *= 1.5 if $rosen;
$y += 0.5 if $rosen;
my ($xx, $yy) = ($x->dummy(1,YPTS), $y->dummy(0,XPTS));

my $z;
if ($rosen) {
  $z = (1 - $xx) ** 2 + 100 * ($yy - ($xx ** 2)) ** 2;
  # The log argument may be zero for just the right grid.
  $z = log ($z);
} else {
  my $r = sqrt ($xx * $xx + $yy * $yy);
  $z = exp (-$r * $r) * cos (2.0 * pi * $r);
}
$z->inplace->setnonfinitetobad;
$z->inplace->setbadtoval(-5); # -MAXFLOAT would mess-up up the scale

my (@indexymin, @indexymax);
my $square_root = sqrt(1. - hclip(( (sequence(XPTS) - $x0) / $a ) ** 2, 1));
# Add 0.5 to find nearest integer and therefore preserve symmetry
# with regard to lower and upper bound of y range.
my $indexymin = lclip( 0.5 + $y0 - $b * $square_root, 0 )->indx;
# indexymax calculated with the convention that it is 1
# greater than highest valid index.
my $indexymax = hclip( 1 + ( 0.5 + $y0 + $b * $square_root ), YPTS )->indx;
my $zlimited = zeroes (XPTS, YPTS);
for my $i ( $indexxmin..$indexxmax-1 ) {
  my $j = [ $indexymin->at($i), $indexymax->at($i) ];
  $zlimited->index($i)->slice($j) .= $z->index($i)->slice($j);
}

my ($zmin, $zmax) = (min($z), max($z));
my $nlevel = LEVELS;
my $step = ($zmax - $zmin) / ($nlevel + 1);
my $clevel = $zmin + $step + $step * sequence ($nlevel);

pllightsource (1., 1., 1.);

for (my $k = 0; $k < 2; $k++) {
  for (my $ifshade = 0; $ifshade < 5; $ifshade++) {
    pladv (0);
    plvpor (0.0, 1.0, 0.0, 0.9);
    plwind (-1.0, 1.0, -0.9, 1.1);
    plcol0 (3);
    plmtex (1.0, 0.5, 0.5, "t", $title[$k]);
    plcol0(1);
    if ($rosen) {
      plw3d (1.0, 1.0, 1.0, -1.5, 1.5, -0.5, 1.5, $zmin, $zmax,
             $alt[$k], $az[$k]);
    } else {
      plw3d (1.0, 1.0, 1.0, -1.0, 1.0, -1.0, 1.0, $zmin, $zmax,
             $alt[$k], $az[$k]);
    }

    plbox3 (0.0, 0, 0.0, 0, 0.0, 0,
            "bnstu", "x axis", "bnstu", "y axis", "bcdmnstuv", "z axis");
    plcol0 (2);

    cmap1_init(($ifshade == 0) || 0);
    if ($ifshade == 0) {        # diffuse light surface plot
      plsurf3d($x, $y, $z, 0, pdl []);
    } elsif ($ifshade == 1) { # magnitude colored plot
      plsurf3d($x, $y, $z, MAG_COLOR, pdl []);
    }
    elsif ($ifshade == 2) {     # magnitude colored plot with faceted squares
      plsurf3d($x, $y, $z, MAG_COLOR | FACETED, pdl []);
    } elsif ($ifshade == 3) {   # magnitude colored plot with contours
      plsurf3d($x, $y, $z, MAG_COLOR | SURF_CONT | BASE_CONT, $clevel);
    } else {          # magnitude colored plot with contours and index limits.
      plsurf3dl(
        $x, $y, $zlimited, MAG_COLOR | SURF_CONT | BASE_CONT, $clevel,
        $indexxmin, $indexxmax, $indexymin, $indexymax,
      );
    }
  }
}

plend ();
