# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use strict;
use warnings;

use Test::More tests => 6;

use lib 'lib';

use Physics::Particles;
ok(1, "Module loaded."); # If we made it this far, we're ok.

#########################

use constant G      => 6.67e-11;
use constant MEARTH => 5.972E24;
use constant AU     => 149597870691;
use constant DAY    => 60*60*24;

my $sim = Physics::Particles->new();

ok(ref $sim eq 'Physics::Particles', "Simulator created.");

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

ok(1, "add_force did not croak.");

$sim->add_particle(
  x  => -0.001541580,
  y  => -0.005157481,
  z  => -0.002146907,
  vx => 0.000008555,
  vy => 0.000000341,
  vz => -0.000000084,
  m  => 333054.25,
  n  => 'sun',
);

$sim->add_particle(
  x  => 0.352233521,
  y  => -0.117718043,
  z  => -0.098961836,
  vx => 0.004046276,
  vy => 0.024697922,
  vz => 0.0127737,
  m  => 0.05525787,
  n  => 'mercury',
);

$sim->add_particle(
  x  => 0.033968222,
  y  => -0.666660228,
  z  => -0.301998971,
  vx => 0.020058354,
  vy => 0.001549021,
  vz => -0.00057222,
  m  => 0.8153047,
  n  => 'venus',
);

$sim->add_particle(
  x  => -0.178474939,
  y  => 0.882278285,
  z  => 0.382595849,
  vx => -0.017160761,
  vy => -0.003032468,
  vz => -0.001315514,
  m  => 1,
  n  => 'earth',
);

$sim->add_particle(
  x  => -0.179738396,
  y  => 0.884150219,
  z  => 0.383544671,
  vx => -0.017640031,
  vy => -0.003408191,
  vz => -0.001432299,
  m  => 0.01230743,
  n  => 'moon',
);

$sim->add_particle(
  x  => 1.277891009,
  y  => 0.577739792,
  z  => 0.230622826,
  vx => -0.005679889,
  vy => 0.012423137,
  vz => 0.005851583,
  m  => 0.10753348,
  n  => 'mars',
);


ok(1, "add_particle did not croak.");

my $iterations = 10;
my @pos = ([],[],[],[],[],[]);
foreach (1..$iterations) {
   my $p_no = 0;
   foreach my $p (@{ $sim->{p} }) {
     push @{$pos[$p_no]}, [ $p->{x}, $p->{y}, $p->{z} ];
     $p_no++;
   }
   $sim->iterate_step(1);
}

ok(1, "iterate_step() did not croak.");

my $state = $sim->dump_state();

ok(1, "dump_state() did not croak.");
