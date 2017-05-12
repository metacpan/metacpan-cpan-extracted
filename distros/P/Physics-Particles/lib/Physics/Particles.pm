
# See the POD documentation at the end of this
# document for detailed copyright information.
# (c) 2002-2003 Steffen Mueller, all rights reserved.

package Physics::Particles;

use 5.006;
use strict;
use warnings;

use constant C_VACUUM         => 299792458;
use constant C_VACUUM_SQUARED => 299792458 * 299792458;

use Carp;

use Data::Dumper;

use vars qw/$VERSION/;
$VERSION = '1.02';


# constructor new
# 
# Does not require any arguments. All arguments
# directly modify the object as key/value pairs.
# returns freshly created simulator object.

sub new {
	my $proto = shift;
	my $class = ref $proto || $proto;

	# Make a new object with default values.
	my $self = {
		forces => [], # All forces (callbacks) will be stored here.
		p      => [], # All particles (hashrefs) will be stored here.
		p_attr => {
			x => 0,
			y => 0,
			z => 0,
			vx => 0,
			vy => 0,
			vz => 0,
			m => 1,
			n => '',
		},
		@_
	};

	bless $self => $class;
}


# method set_particle_default
#
# Takes a hash reference whichis then used as is for
# particle default attributes such as position, velocity, mass,
# unique ID, or whatever properties you fancy.

sub set_particle_default {
	my $self = shift;
	my $hashref = shift;
	
	ref $hashref eq 'HASH'
	  or croak "Must pass hash reference to set_particle_default().";
	
	$self->{p_attr} = $hashref;
	return 1;
}

# method add_particle
# 
# Takes key/value pairs of particle attributes.
# Attributes default to whatever has been set using
# set_particle_default.
# A new particle represented by the attributes is then
# created in the simulation and its particle number is
# returned. Attributes starting with an underscore are
# reserved to internal attributes (so don't use any of them).

sub add_particle {
	my $self = shift;
	
	my $particle = {
		%{$self->{p_attr}},
		@_,
		_fx => 0,
		_fy => 0,
		_fz => 0,
	};
	
	my $particle_no = $self->_make_particle();
	
	$self->{p}[$particle_no] = $particle;
	
	return $particle_no;
}


# private method _make_particle
#
# Returns a currently unused particle number or
# appends an empty particle to the particle list.

sub _make_particle {
	my $self = shift;
	my $count = 0;
	foreach (@{$self->{p}}) {
		return $count unless ref $_;
		$count++;
	}
	
	push @{ $self->{p} }, undef;
	return $count;
}


# method clear_particles
# 
# Removes all particles from the simulation.

sub clear_particles {
	my $self = shift;
	$self->{p} = [];
	return 1;
}


# method remove_particle
#
# Removes a specific particle from the simulation.
# Takes the particle number as argument.
# Returns 1 on success, 0 otherwise.

sub remove_particle {
	my $self = shift;
	my $particle_no = shift;
	
	return 0 if $particle_no < 0 || $particle_no > $#{$self->{p}};
	
	$self->{p}[$particle_no] = undef;
	
	return 1;
}


# method add_force
#
# Adds a new force to the simulation.
# Takes a subroutine reference (the force) as argument,
# appends it to the list of forces and returns the force it
# just appended. Second argument is optional and defaults to false.
# It is a boolean indicating whether or not the force is symmetric.
# Symmetric means that the force particle1 excerts on particle2
# is exactly zero minus the force particle2 excerts on particle1.

sub add_force {
	my $self = shift;
	my $force = shift;
	my $symmetric = shift;
	$symmetric = 0 unless defined $symmetric;
	
	push @{$self->{forces}}, [$force, $symmetric];
	return $force;
}


# method iterate_step
#
# Applies all forces (excerted by every particle) to all particles.
# That means this is of complexity no_particles*no_particles*forces.
# Takes a list of additional parameters as argument that will be
# passed to every force subroutine.

sub iterate_step {
	my $self = shift;
	my @params = @_;

	my $forces    = [];
	foreach (@{ $self->{p} }) {
		push @$forces, [$_->{_fx}, $_->{_fy}, $_->{_fz}];
		$_->{_fx} = $_->{_fy} = $_->{_fz} = 0;
	}

	my $new_state = [];

	my $p_no = 0;
	foreach my $p (@{ $self->{p} }) {
		my $new_p = { %$p };
		push @$new_state, $new_p;
		my $f = $forces->[$p_no];
		foreach my $force_def (@{$self->{forces}}) {
			my $symm = $force_def->[1];
			my $force = $force_def->[0];
			my $exc_no = 0;
			foreach my $excerter (@{$self->{p}}) {
				last if $symm and $exc_no >= $p_no;
				$exc_no++, next if $exc_no == $p_no;
				my @this_f = $force->(
					$p,
					$excerter,
					\@params
				);
				$f->[0] += $this_f[0];
				$f->[1] += $this_f[1];
				$f->[2] += $this_f[2];
				if ($symm) {
					$forces->[$exc_no][0] -= $this_f[0];
					$forces->[$exc_no][1] -= $this_f[1];
					$forces->[$exc_no][2] -= $this_f[2];
				}
				$exc_no++;
			}
		}
		$p_no++;
	}

	$p_no = 0;
	foreach my $new_p (@$new_state) {
		my $f = $forces->[$p_no++];
		# accel_i = force_i / mass (i-th component)
		my $m = $new_p->{m} /
			sqrt(1 -
				($new_p->{vx}**2 +
				 $new_p->{vy}**2 +
				 $new_p->{vz}**2) /
			 	C_VACUUM_SQUARED
			);
		my @a = ($f->[0] / $m, $f->[1] / $m, $f->[2] / $m);

		@a = map $_ * $params[0], @a;
		
		$new_p->{x} += $new_p->{vx} * $params[0] +
				0.5 * $a[0] * $params[0];
		$new_p->{y} += $new_p->{vy} * $params[0] +
				0.5 * $a[1] * $params[0];
		$new_p->{z} += $new_p->{vz} * $params[0] +
				0.5 * $a[2] * $params[0];

		$new_p->{vx} += $a[0];
		$new_p->{vy} += $a[1];
		$new_p->{vz} += $a[2];
	}
	
	$self->{p} = $new_state;

	return 1;
}


# method dump_state
# 
# Returns a Data::Dumper dump of the state of all particles.

sub dump_state {
	my $self = shift;
	return Dumper($self->{p});
}

1;


__END__

=pod

=head1 NAME

Physics::Particles - Simulate particle dynamics

=head1 VERSION

Current version is 1.00.
Version 1.00 and later are incompatible to versions below 1.00.

=head1 SYNOPSIS

  use Physics::Particles;
  
  my $sim = Physics::Particles->new();
  
  $sim->add_force(
     sub {
        my $particle = shift;
        my $excerter = shift;
        my $params = shift;
        my $time_diff = $params->[0];
	# ...
        return($force_x, $force_y, $force_z);
     },
     1   # 1 => symmetric force, 0 => asymmetric force
  );
  
  $sim->add_particle(
    x  => -0.001541580, y  => -0.005157481, z  => -0.002146907,
    vx => 0.000008555,  vy => 0.000000341,  vz => -0.000000084,
    m  => 333054.25,    n  => 'sun',
  );
  
  $sim->add_particle(
    x  => 0.352233521,  y  => -0.117718043, z  => -0.098961836,
    vx => 0.004046276,  vy => 0.024697922,  vz => 0.0127737,
    m  => 0.05525787,   n  => 'mercury',
  );
  
  # [...]
  
  my $iterations = 1000;
  foreach (1..$iterations) {
     $sim->iterate_step(1);
  }
  
  my $state = $sim->dump_state();
  
  # Now do something with it. You could, for example,
  # use GNUPlot or the Math::Project3D module to create
  # 3D graphs of the data.

=head1 DESCRIPTION

Physics::Particles is a facility to simulate movements of
a small number of particles under a small number of forces
that every particle excerts on the others. Complexity increases
with particles X particles X forces, so that is why the
number of particles should be low.

In the context of this module, a particle is no more or less
than a set of attributes like position, velocity, mass, and
charge. The example code and test cases that come with the
distribution simulate the inner solar system showing that
when your scale is large enough, planets and stars may
well be approximated as particles. (As a matter of fact,
in the case of gravity, if the planet's shape was a sphere,
the force of gravity outside the planet would always be
its mass times the mass of the body it excerts the force on
times the gravitational constant divided by the distance
squared.)

Simulation of microscopic particles is a bit more difficult
due to floating point arithmetics on extremely small values.
You will need to choose your constant factors wisely.

=head2 Forces

As you might have gleamed from the synopsis, you will have to
write subroutines that represent forces which the particles
of the simulation excert on one another. You may specify
(theoretically) any number of forces.

The force subroutines are passed three parameters. First is the
particle that should be modified according to the effect of the force.
Second is the particle that excerts the force, and the third
argument will be an array reference of parameters passed to the
iterate_step method at run time. The first element of this array
I<should> be the time slice for which you are to calculate the force vector.

As of version 1.00, forces may no longer modify the particles themselves.
Instead, they are to return three values indication x,y,z components of
the force vector. Furthermore, the acceleration is calculated from the force
according to special relativity.

Physics::Particles can only simulate forces between I<any> two particles.
A particle cannot excert a force on itself. (The force subroutine isn't even
called if the excerter particle and the particle-to-be-moved are identical.)

To alleviate this shortcoming, there are the Physics::Springs and
Physics::Springs::Friction modules which subclass Physics::Particles to extend
it towards forces between two I<specific> particles (Physics::Springs) and
force fields (Physics::Springs::Friction).

=head2 Methods

=over 4

=item new

new() is the constructor for a fresh simulation.
It does not require any arguments. All arguments
directly modify the object as key/value pairs.
Returns newly created simulator object.

=item add_particle

This method takes key/value pairs of particle attributes.
Attributes default to whatever has been set using
set_particle_default.
A new particle represented by the attributes is then
created in the simulation and its particle number is
returned. Attributes starting with an underscore are
reserved to internal attributes (so don't use any of them).


=item remove_particle

This method removes a specific particle from the simulation.
It takes the particle number as argument and returns
1 on success, 0 otherwise.

=item clear_particles

This method removes all particles from the simulation.

=item set_particle_default

Takes a hash reference as argument which is then used
for particle default attributes such as position, velocity, mass,
unique ID, or whatever properties you fancy.

You should not change the defaults after adding particles.
You knew that doesn't make sense, did you?

=item add_force

This method adds a new force to the simulation.
It takes a subroutine reference (the force) as argument,
appends it to the list of forces and returns the force it
just appended.
Second argument to add_force() is optional and defaults to false.
It is a boolean indicating whether or not the force is symmetric.
Symmetric means that the force particle1 excerts on particle2
is exactly zero minus the force particle2 excerts on particle1.

=item iterate_step

This method applies all forces (excerted by every particle) to all particles.
That means this is of complexity no_particles * (no_particles-1) * forces.
( O(n**2 * m) or O(n**3) )
iterate_step() takes a list of additional parameters as argument that will be
passed to every force subroutine. (The first argument should be
the duration of the iteration so the forces know how to calculate
the effects on the particles.

=item dump_state

This method returns a Data::Dumper dump of the state of all particles.

=back

=head1 AUTHOR

Steffen Mueller, mail at steffen-mueller dot net

=head1 COPYRIGHT

Copyright (c) 2002-2005 Steffen Mueller. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

You may find the newest version of this module on CPAN or
http://steffen-mueller.net

For more elaborate simulations:
L<Physics::Springs>, L<Physics::Springs::Friction>

For a reasonably convenient way of visualizing the produced data:
L<Math::Project3D>, L<Math::Project3D::Plot>

=cut

