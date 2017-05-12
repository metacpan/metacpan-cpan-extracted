#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';

use Physics::Particles;

#########################

use constant G      => 6.67e-11;
use constant MEARTH => 5.972E24;
use constant AU     => 149597870691;
use constant DAY    => 60*60*24;

use Math::Project3D::Plot;

my $sim = Physics::Particles->new();
   $sim->add_force(
   sub {
	my $p = shift;
	my $excerter = shift;
	my $params = shift;
	my $time_diff = $params->[0];

	my $x_dist = ($excerter->{x} - $p->{x});
	my $y_dist = ($excerter->{y} - $p->{y});
	my $z_dist = ($excerter->{z} - $p->{z});

	my $dist = sqrt($x_dist**2 + $y_dist**2 + $z_dist**2);
	
	# force = m1*m2*unit_vector_from_r1_to_r2/distance**2
	# a = f/m1 (module does that for us)

	my $const = (((G * MEARTH) / AU) / AU);
	my $force =
		(
			$dist == 0 ? 0 :
			$const * $p->{m} * $excerter->{m} / $dist**3
			#const = (G * MEARTH / AU / AU)
		);

	return(
		$force * $x_dist,
		$force * $y_dist,
		$force * $z_dist,
	);
   },
   1 # symmetric force
   );
   
   $sim->add_particle(
     x  => -0.001541580, y  => -0.005157481, z  => -0.002146907,
     vx => 0.000008555,  vy => 0.000000341, vz => -0.000000084,
     m  => 333054.25,    n  => 'sun',
   );
   
   $sim->add_particle(
     x  => 0.352233521, y  => -0.117718043, z  => -0.098961836,
     vx => 0.004046276, vy => 0.024697922,  vz => 0.0127737,
     m  => 0.05525787,  n  => 'mercury',
   );
   
   $sim->add_particle(
     x  => 0.033968222, y  => -0.666660228, z  => -0.301998971,
     vx => 0.020058354, vy => 0.001549021,  vz => -0.00057222,
     m  => 0.8153047,   n  => 'venus',
   );

   $sim->add_particle(
     x  => -0.178474939, y  => 0.882278285, z  => 0.382595849,
     vx => -0.017160761, vy => -0.003032468,vz => -0.001315514,
     m  => 1,            n  => 'earth',
   );
   
   $sim->add_particle(
     x  => -0.179738396, y  => 0.884150219, z  => 0.383544671,
     vx => -0.017640031, vy => -0.003408191,vz => -0.001432299,
     m  => 0.01230743,   n  => 'moon',
   );
   
   $sim->add_particle(
     x  => 1.277891009, y  => 0.577739792, z  => 0.230622826,
     vx => -0.005679889,vy => 0.012423137, vz => 0.005851583,
     m  => 0.10753348,  n  => 'mars',
   );

my @pictures = (1..100);
foreach my $picture (@pictures) {
   
   my $iterations = 25;
   my @pos = ([],[],[],[],[],[]);
   foreach (1..$iterations) {
      my $p_no = 0;
      foreach my $p (@{ $sim->{p} }) {
        push @{$pos[$p_no]}, [ $p->{x}, $p->{y}, $p->{z} ];
        $p_no++;
      }
      $sim->iterate_step(.1);
   }
   
   my $img = Imager->new(xsize=>400,ysize=>400);
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
     scale      => 170,
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
   
   foreach (0..5) {
      $plotter->plot_range(
        color  => $color[$_],
        params => [
                    [$_],
                    [0, $iterations-1, 1],
                  ],
        type   => 'line',
      );
   }

   $img->write(file=>sprintf("t%03i.png",$picture)) or die $img->errstr;
   print "Wrote picture number $picture\n";
   $picture = $img;
}

