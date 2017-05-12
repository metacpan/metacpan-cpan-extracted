package Physics::Springs::Friction;

use 5.006;
use strict;
use warnings;

use Carp;
use base 'Physics::Springs';

use constant FFORCES => '_PhSpringsFriction_friction_forces';
use Sub::Assert;

our $VERSION = '1.01';

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = $class->SUPER::new();
	$self->{FFORCES} = [];
	return $self;
}

assert
	context => 'novoid',
	pre => '@PARAM == 1',
	post => '@RETURN == 1',
	sub => 'new';


sub add_friction {
	my $self   = shift;

	my $impl = shift;
	my $magn = shift;

	my $friction = {
		implementation => 'stokes',
		magnitude      => 0.1,
	};
	if (defined $impl) {
		unless (ref($impl) eq 'CODE' or
			$impl eq 'stokes' or
			$impl eq 'newton'
		       ) {

		    	$impl = <<ENDIMPL;
sub {
	my \$P = shift;
	my \$M = shift;
	my \$F = [0, 0, 0];
	$impl
	return \@\$F;
}
ENDIMPL
			local $@;
			my $closure = eval $impl;
			croak "Error while evaluating friction " .
				"implementation.\n ($@)" if $@;
			$impl = $closure;
		}
		$friction->{implementation} = $impl;
	}

	$friction->{magnitude} = $magn if defined $magn;

	push @{$self->{FFORCES}}, $friction;
	return $#{$self->{FFORCES}};
}

assert
	pre =>	[
			'@PARAM <= 3 && @PARAM > 0',
			'@PARAM == 1 ? 1 : defined($PARAM[1])',
			'@PARAM != 3 ? 1 : defined($PARAM[2])',
		],
	post =>	'$VOID || (@RETURN == 1 and $RETURN >= 0)',
	sub => 'add_friction';
	


sub iterate_step {
	my $self      = shift;
	my @params    = @_;
	my $time_diff = $params[0];
	foreach my $friction (@{$self->{FFORCES}}) {
		my $magnitude = $friction->{magnitude};
		my $func      = $friction->{implementation};
		if ($func eq 'stokes') {
			# F = 6*PI*eta*r*v
			# magnitude = 6*PI*eta*r
			foreach my $P (@{$self->{p}}) {
				my ($vx, $vy, $vz) = (
					$P->{vx}, $P->{vy}, $P->{vz}
				);
					
				my $v = sqrt(
						$vx**2 +
						$vy**2 +
						$vz**2
				);
				
				next if $v == 0;

				my $f = $magnitude * $v;

				$P->{_fx} -= $f * ($vx/$v);
				$P->{_fy} -= $f * ($vy/$v);
				$P->{_fz} -= $f * ($vz/$v);
			}
		}
		elsif ($func eq 'newton') {
			# F = 0.5*c*rho*A*v^2
			# magnitude = c*rho*A
			foreach my $P (@{$self->{p}}) {
				my ($vx, $vy, $vz) = (
					$P->{vx}, $P->{vy}, $P->{vz}
				);
					
				my $v = sqrt(
						$vx**2 +
						$vy**2 +
						$vz**2
					);
				
				next if $v == 0;
				
				my $f = 0.5 * $magnitude * $v**2;

				$P->{_fx} -= $f * ($vx/$v);
				$P->{_fy} -= $f * ($vy/$v);
				$P->{_fz} -= $f * ($vz/$v);
			}
		}
		else {
			foreach my $particle (@{$self->{p}}) {
				my @this_f = $func->({%$particle}, $magnitude);
				$particle->{_fx} += $this_f[0];
				$particle->{_fy} += $this_f[1];
				$particle->{_fz} += $this_f[2];
			}
		}
	}
#	use Data::Dumper;
#	print Dumper $self->{p};
	$self->SUPER::iterate_step(@params);
}
	
1;
__END__

=head1 NAME

Physics::Springs::Friction - Simulate Dynamics with Springs and Friction

=head1 SYNOPSIS

  use Physics::Springs::Friction;
  
  my $sim = Physics::Springs::Friction->new();

=head1 ABSTRACT

  Simulate particle dynamics with springs and friction.

=head1 DESCRIPTION

This module is intended as an add-on to the Physics::Springs (from version
1.00) and Physics::Particles (from version 1.00) modules and may be used
to simulate particle dynamics including spring-like forces between any two
particles you specify and friction-like forces that are applied to the
movement of all particles.

The module extends the API of Physics::Springs by one method which is
documented below. Please see the documentation to Physics::Springs and
Physics::Particles for more information about the API.

There are several particle properties required by Physics::Springs::Friction
in order to work: These are the x/y/z coordinates, the vx/vy/vz
velocity vector components, and a non-zero mass 'm'.

=head2 Method add_friction

This method adds a new frictional force to the simulation. This force
can be thought of as an external force field that applies to any particles
depending on any of its properties. That means you're welcome to abuse
this functionality to implement any kind of external force fields.

The method is to be called with zero to two arguments. Without arguments,
the default friction implementation will be used which is meant to model
Stokes' friction. More on Stokes' friction in the section named 'On Stokes'
Friction'. It is strongly suggested you skim it even if you have a strong
background in Physics. Same applies to the section 'On Newtonian Friction'.

With one argument, you may choose what type of friction to apply. Valid
first arguments are either 'stokes', 'newton', an anonymous subroutine, or
an arbitrary string representing a piece of code that uses a particle $P
and a friction-magnitude $M to compute the force excerted on the particle.
The force components are expected to be stored in an existing variable $F
that contains an array reference to an array of [0, 0, 0]. In case of the
anonymous subroutine, the subroutine is expected to return the three
force components. This behaviour has changed in version 1.00.

With two arguments, the second argument sets the friction-magnitude.

=head2 iterate_step

Iterates next simulation step. Please refer to the documentation of the
super method to this in L<Physics::Particles>.

=head2 On Friction

Friction is one of the concepts that physicists hardly understand because
there are simply too many processes involved. We can, however, describe
macroscopic effects of friction in many cases. There are several formulars
that describe special cases of frictional forces. Two of these, Stokes'
friction and Newtonian friction are implemented in this module. Using
anonymous subroutines or code strings that compute friction, it is
possible to extend the module's functionality.

=head2 On Stokes' Friction

The formula to calculate Stokes' friction of a sphere of radius r is

  Force = 6 * Pi * r * eta * velocity

Trivially, the force is antiparallel to the velocity. Stokes' friction is
usually applied when a rather small object moves rather slowly through a
fluid or gas of viscosity eta.

In the Physics::Springs::Friction implementation, the friction is simply
computed as

  Force = magnitude * velocity
  
  Hence:
  magnitude = 6 * Pi * r * eta (for small spheres)

The magnitude is passed as the second argument to the add_friction() method.
This behaviour was chosen to allow for flexibility concerning geometry and
viscosity.

=head2 On Newtonian Friction

The formula to calculate Newtonian friction of a body in a fluid:

  Force = 1/2 * c * rho * area * velocity^2

rho is the density of the fluid, the area is the projected area of the body
in direction of movement, and c is coefficient that is determined by the
body's geometry. For hydro-dynamically good geometries: c < 1. For
spheres: c = about 1. For hydro-dynamically inefficient geometries: c > 1.

Newtonian friction is usually applied in cases of high velocity and
bodies of significant size. As with Stokes' friction, all constants are
summed up into the magnitude property of the friction as follows:

  Force = magnitude * velocity^2
  magnitude = 0.5*c*rho*area

=head1 DIAGNOSTICS

Here is a list of some not-so-selfexplanatory errors:

  "Precondition 1 for Physics::Springs::Friction::new failed."
  new() does not expect any arguments.

  "Postcondition 1 for Physics::Springs::Friction::new failed."
  Please contact the author about this error.
  
  "Precondition 1 for Physics::Springs::Friction::add_friction failed."
  add_friction() takes between 0 and 2 arguments and is an object method.

  "Precondition 2 for Physics::Springs::Friction::add_friction failed."
  add_friction() expects a defined first argument if any.
  
  "Precondition 3 for Physics::Springs::Friction::add_friction failed."
  add_friction() expects a defined second argument if any.

  "Postcondition 1 for Physics::Springs::Friction::add_friction failed."
  add_friction() screwed up. Please contact the author about this error.

=head1 SEE ALSO

L<Physics::Particles>, L<Physics::Springs>

L<Math::Project3D>, L<Math::Project3D::Plot> for a reasonably
simple way to visualize your data.

http://steffen-mueller.net or CPAN for the current version of this module.

=head1 AUTHOR

Steffen Mueller, E<lt>friction-module at steffen-mueller dot netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2005 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

