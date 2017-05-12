package Physics::Springs;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.01';

use Carp;
use Physics::Particles;
use Sub::Assert;

use base 'Physics::Particles';


sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = $class->SUPER::new();
	$self->{_PhSprings_springs} = [];
	return $self;
}

assert
	pre     => '@PARAM == 1',
	post    => '@RETURN == 1',
	context => 'novoid',
	action  => 'croak',
	sub     => 'new';

sub add_spring {
	my $self   = shift;
	my %args   = @_;
	my $spring = {};
	my $k      = $args{k};
	my $p1     = $args{p1};
	my $p2     = $args{p2};
	my $l      = $args{l};

	defined($k) && defined($p1) && defined($p2)
		or croak("You need to supply several named arguments.");

	# default to being relaxed
	if (not defined $l) {
		my $dist = sqrt(
			( ($self->{p}[$p1]{x} - $self->{p}[$p2]{x}) )**2 +
			( ($self->{p}[$p1]{y} - $self->{p}[$p2]{y}) )**2 +
			( ($self->{p}[$p1]{z} - $self->{p}[$p2]{z}) )**2
		);
		$l = abs($dist);
	}

	$spring->{k}   = $k;
	$spring->{p1}  = $p1;
	$spring->{p2}  = $p2;
	$spring->{len} = $l;

	push @{$self->{_PhSprings_springs}}, $spring;
	return $#{$self->{_PhSprings_springs}};
}

assert
	pre     => '@PARAM >= 9',
	post    => '$VOID or @RETURN == 1 && $RETURN >= 0',
	action  => 'croak',
	sub     => 'add_spring';

sub iterate_step {
	my $self      = shift;
	my @params    = @_;
	my $time_diff = $params[0];
	foreach my $spring (@{$self->{_PhSprings_springs}}) {
		my $p1 = $self->{p}[$spring->{p1}];
		my $p2 = $self->{p}[$spring->{p2}];
		my $l  = $spring->{len};
		my $k  = $spring->{k};

		my $dist =  sqrt(
			( ($p1->{x} - $p2->{x}) )**2 +
			( ($p1->{y} - $p2->{y}) )**2 +
			( ($p1->{z} - $p2->{z}) )**2
		);

		my $force1 = $k * ($dist-$l);
		my $force2 = -$force1;

		my $dx = ($p2->{x} - $p1->{x}) / $dist;
		my $dy = ($p2->{y} - $p1->{y}) / $dist;
		my $dz = ($p2->{z} - $p1->{z}) / $dist;

		$p1->{_fx} += $force1 * $dx;
		$p1->{_fy} += $force1 * $dy;
		$p1->{_fz} += $force1 * $dz;

		$p2->{_fx} += $force2 * $dx;
		$p2->{_fy} += $force2 * $dy;
		$p2->{_fz} += $force2 * $dz;
	}

	$self->SUPER::iterate_step(@params);
}

1;
__END__

=head1 NAME

Physics::Springs - Simulate Particle Dynamics with Springs

=head1 SYNOPSIS

  use Physics::Springs;

=head1 ABSTRACT

  Simulate particle dynamics with springs.

=head1 DESCRIPTION

This module is intended as an add-on to the Physics::Particles module
(version 1.00 or higher required) and may be used to simulate particle
dynamics including spring-like forces between any two particles you specify.

Since version 1.00 of this module, Physics::Particles version 1.00 is required.
Version 1.00 is neither compatible to earlier versions nor to any versions
below 1.00 of Physics::Particles and Physics::Springs::Friction.

The module extends the API of Physics::Particles by one method which is
documented below. Please see the documentation to Physics::Particles for
more information about the API.

There are several particle properties required by Physics::Springs in
order to work: These are the x/y/z coordinates, the vx/vy/vz
velocity vector components, and a non-zero mass 'm'. Furthermore, it uses
the _fx, _fy, _fz properties which the user should never modify directly.

=head2 Methods

=over 2

=item add_spring

You may use the add_spring method to add springs to the system of particles.
Each spring has a starting and end particle, a relaxed length, and a spring
constant 'k'.

add_spring expects several named arguments. Required arguments are:
The spring constant k, the starting (p1) and end (p2) points.
Optional arguments are: The length of the relaxed spring 'len'.
If len is not specified, the current distance between p1 and p2 will be
used as the length of the relaxed spring.

=item iterate_step

Iterates next simulation step. Please refer to the documentation of the
super method to this in L<Physics::Particles>.

=back

=head1 DIAGNOSTICS

Some error messages you may encounter:

  "Precondition 1 not met for Physics::Springs::new()."
  new() does not take any parameters.
  
  "Postcondition 1 not met for Physics::Springs::new()"
  Complain to the author of the module. He screwed up.

  "Physics::Springs::new called in void context."
  It doesn't make sense to call constructors without action-at-a-distance
  in void context so don't.
  
  "Precondition 1 not met for Physics::Springs::add_spring()"
  add_spring() takes at least nine arguments.

  "Postcondition 1 not met for Physics::Springs::add_spring()"
  Complain to the author of the module. He screwed up.

=head1 SEE ALSO

The newest version of this module may be found on CPAN or
http://steffen-mueller.net

The module this module subclasses: L<Physics::Particles>

A module that adds force field-like forces to the simulation:
L<Physics::Springs::Friction>

L<Math::Project3D>, L<Math::Project3D::Plot> for a reasonably
simple way to visualize your data.

=head1 AUTHOR

Steffen Mueller, E<lt>springs-module at steffen-mueller dot netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2005 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
