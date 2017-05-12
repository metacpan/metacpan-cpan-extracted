# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use lib 'lib';

sub ok{};
use Physics::Springs;
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $sim = Physics::Springs->new();

my $p1 = $sim->add_particle(
  x  => -2,  y  => -2, z  => 0,
  vx => 0,  vy => 0.02,  vz => 0,
  m  => 100000000,  n  => 'Particle1',
);

my $p2 = $sim->add_particle(
  x  => 1,  y  => -2, z  =>  0,
  vx => 0,  vy => 0.02,  vz => 0,
  m  => 100000000,  n  => 'Particle2',
);

my $p3 = $sim->add_particle(
  x  => -1.3, y  => -2, z  => 0,
  vx => 0,  vy => 0.02,  vz => 0,
  m  => 100,  n  => 'Particle3',
);

my $p4 = $sim->add_particle(
  x  => 0.3, y  => -2, z  => 0,
  vx => 0,  vy => 0.02,  vz => 0,
  m  => 100, n  => 'Particle4',
);

$sim->add_spring(k => 10, p1 => $p1, p2 => $p3, l => 1 );
$sim->add_spring(k => 10, p1 => $p3, p2 => $p4, l => 1 );
$sim->add_spring(k => 10, p1 => $p4, p2 => $p2, l => 1 );

my $iterations = 40000; # Make this 1000 to get a reasonable picture.

my @pos = ([],[],[],[],[],[]);
foreach (1..$iterations) {
   my $p_no = 0;
   foreach my $p (@{ $sim->{p} }) {
     push @{$pos[$p_no]}, [ $p->{x}, $p->{y}, $p->{z} ];
     $p_no++;
   }
   $sim->iterate_step(0.005);
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

my $proj2 = Math::Project3D->new(
   plane_basis_vector => [ 0, 0, 0 ],
   plane_direction1   => [ 0.371391, 0.928477, 0 ],
   plane_direction2   => [ 0.371391, 0, 0.928477 ],
);

{
	my $alternate = 0;
	$proj2->new_function(
	  sub { $alternate = 0 if $alternate > 1;
		$pos[$_[0]+$alternate][$_[1]][0]
	      },
	  sub { $pos[$_[0]+$alternate][$_[1]][1] },
	  sub { $pos[$_[0]+$alternate++][$_[1]][2] },
	);
}

my $plotter2 = Math::Project3D::Plot->new(
  image      => $img,
  projection => $proj2,
  scale      => 200,
);

#$plotter2->plot_range(
#  color  => $color[4],
#  params => [
#              [0],
#              [0, $iterations-1, 500],
#            ],
#  type   => 'line',
#);

foreach (0..3) {
   $plotter->plot_range(
     color  => $color[$_],
     params => [
                 [$_],
                 [0, $iterations-1, 30],
               ],
     type   => 'points',
   );

}


   
$img->write(file=>'t.png') or
        die $img->errstr;

