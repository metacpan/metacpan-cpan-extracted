# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

# use lib 'lib';

use Test::More tests => 18;
BEGIN { use_ok('Physics::Springs') };
#sub ok{};
#use Physics::Springs;
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $sim = Physics::Springs->new();
ok(ref $sim eq 'Physics::Springs', 'Create Simulation');

my $p1 = $sim->add_particle(
  x  => -1, y  => -1, z  => -1,
  vx => 0,  vy => .1,  vz => 0,
  m  => 1,  n  => 'Particle1',
);
ok($p1 == 0, 'Create Particle 1');

my $p2 = $sim->add_particle(
  x  => 1,  y  =>  1, z  =>  1,
  vx => 0,  vy => .1,  vz => 0,
  m  => 2,  n  => 'Particle2',
);
ok($p2 == 1, 'Create Particle 2');

my $p3 = $sim->add_particle(
  x  => 0, y  => 0, z  => 0,
  vx => 0,  vy => .1,  vz => 0,
  m  => 3,  n  => 'Particle3',
);
ok($p3 == 2, 'Create Particle 3');

$sim->add_spring(k => 2, p1 => $p1, p2 => $p2, l => 1 );
ok($sim->{_PhSprings_springs}[0]{k}==2, 'Create Spring 1');

$sim->add_spring(k => 1, p1 => $p3, p2 => $p1, l => 1.5 );
ok($sim->{_PhSprings_springs}[1]{p2}==0, 'Create Spring 2');

$sim->add_spring(k => 1, p1 => $p3, p2 => $p2, l => 1.5 );
ok($sim->{_PhSprings_springs}[2]{p2}==1, 'Create Spring 3');

my $iterations = 10; # Make this 1000 to get a reasonable picture.

my @pos = ([],[],[],[],[],[]);
foreach (1..$iterations) {
   my $p_no = 0;
   foreach my $p (@{ $sim->{p} }) {
     push @{$pos[$p_no]}, [ $p->{x}, $p->{y}, $p->{z} ];
     $p_no++;
   }
   $sim->iterate_step(0.01);
   ok(1, 'Iterated.');
}





=begin comment

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
  scale      => 100,
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


foreach (0..2) {
   $plotter->plot_range(
     color  => $color[$_],
     params => [
                 [$_],
                 [0, $iterations-1, 1],
               ],
     type   => 'line',
   );
}

$img->write(file=>'t.png') or
        die $img->errstr;

=cut
