#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';

use Physics::Springs::Friction;

my $sim = Physics::Springs::Friction->new();

my $p1 = $sim->add_particle(
  x  => -2,  y  => -1.5, z  => 0,
  vx => 0,  vy => 0.04,  vz => 0,
  m  => 5,  n  => 'Particle1',
);

my $p2 = $sim->add_particle(
  x  => 0,  y  => -1.5, z  =>  0,
  vx => 0,  vy => 0.04,  vz => 0,
  m  => 5,  n  => 'Particle2',
);

$sim->add_spring(k => 0.25, p1 => $p1, p2 => $p2, l => 1 );

$sim->add_friction('stokes', .05);

my $iterations = 25000; # Make this >5000 to get a reasonable picture.

my @pos = ([],[],[],[],[],[]);
foreach (1..$iterations) {
   my $p_no = 0;
   foreach my $p (@{ $sim->{p} }) {
     push @{$pos[$p_no]}, [ $p->{x}, $p->{y}, $p->{z} ];
     $p_no++;
   }
   $sim->iterate_step(0.02);
}



# Only plotting done below. Uncomment for a picture.

use Math::Project3D::Plot;

my $img = Imager->new(xsize=>1024,ysize=>768);
my $proj = Math::Project3D->new(
   plane_basis_vector => [ 0, 0, 0 ],
   plane_direction1   => [ 0.371391, 0.928477, 0 ],
   plane_direction2   => [ 0.371391, 0, 0.928477 ],
);

$proj->new_function(
  sub { $pos[$_[0]][$_[1]][0] },
  sub { $pos[$_[0]][$_[1]][1] },
  sub { $pos[$_[0]][$_[1]][2] },
);

my @color;

push @color, Imager::Color->new( 255, 255, 0   ); # sun
push @color, Imager::Color->new( 0,   255, 0   ); # mercury
push @color, Imager::Color->new( 255, 0,   255 ); # venus
push @color, Imager::Color->new( 0,   0,   255 ); # earth
push @color, Imager::Color->new( 255, 255, 255 ); # moon
push @color, Imager::Color->new( 255, 0,   0   ); # mars

my $x_axis     = Imager::Color->new(40, 40, 40);
my $y_axis     = Imager::Color->new(40, 40, 40);
my $z_axis     = Imager::Color->new(40, 40, 40);
my $background = Imager::Color->new(0,   0, 0);

$img->flood_fill(x=>0,y=>0,color=>$background);

my $plotter = Math::Project3D::Plot->new(
  image      => $img,
  projection => $proj,
  scale      => 200,
);

$plotter->plot_axis( # x axis
  vector => [1, 0, 0],
  color  => $x_axis,
  length => 100,
);

$plotter->plot_axis( # y axis
  vector => [0, 1, 0],
  color  => $y_axis,
  length => 100,
);

$plotter->plot_axis( # z axis
  vector => [0, 0, 1],
  color  => $z_axis,
  length => 100,
);

foreach (0..1) {
   $plotter->plot_range(
     color  => $color[$_],
     params => [
                 [$_],
                 [0, $iterations-1, 5],
               ],
     type   => 'line',
   );

}
   
$img->write(file=>'t.png') or
        die $img->errstr;


