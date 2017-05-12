package SDL::Tutorial::3DWorld::Actor;

=pod

=head1 NAME

SDL::Tutorial::3DWorld::Actor - A moving object within the game world

=head1 SYNOPSIS

  # Create a vertical stack of teapots
  my @stack = ();
  foreach my $height ( 1 .. 10 ) {
      push @stack, SDL::Tutorial::3DWorld::Actor->new(
          X => 0,
          Y => $height * 0.30, # Each teapot is 30cm high
          Z => 0,
      );
  }

=head1 DESCRIPTION

Within the game, the term "Actor" is used to describe anything that has
a shape and moves around the world based on it's own set of rules.

In practice, an actor could be anything from a bullet or a grenade flying
through the air, to a fully articulated roaring dragon with flaming breath
and it's own artificial intelligence.

To the game engine, all of these "actors" are basically the same. They are
merely things that need to describe where they are and what they look like
each time the engine wants to render a frame.

In this demonstration, the default actor is a 30cm x 30cm teapot. We are
using a teapot because it is the "official" test mesh object for OpenGL
and is built directly into the library itself via the C<glutCreateTeapot>
function.

=head1 METHODS

=cut

use 5.008;
use strict;
use warnings;
use SDL::Tutorial::3DWorld::OpenGL   ();
use SDL::Tutorial::3DWorld::Material ();

our $VERSION = '0.33';

=head2 new

  my $teapot = SDL::Tutorial::3DWorld::Actor->new;

The C<new> constructor is used to create a new actor within the 3D World.

In the demonstration implementation, the default actor consists of a teapot.

=cut

sub new {
	my $class = shift;
	my $self  = bless {
		# Most objects are stored at the correct size
		scale    => 0,

		# Place objects at the origin by default
		position => [ 0, 0, 0 ],

		# Do not rotate by default
		orient   => 0,

		# Actors with non-vector velocity are shortcut by the main
		# move routine
		velocity => 0,

		# Most things in the world are solid
		blending => 0,

		# Most things are visible by default
		hidden   => 0,

		# Override defaults
		@_,
	}, $class;

	# Automatically support uniform scaling
	if ( $self->{scale} and not ref $self->{scale} ) {
		$self->{scale} = [
			$self->{scale},
			$self->{scale},
			$self->{scale},
		];
	}

	# Upgrade material parameters to material object
	if ( ref $self->{material} eq 'HASH' ) {
		$self->{material} = SDL::Tutorial::3DWorld::Material->new(
			%{$self->{material}}
		);
	}

	return $self;
}

=pod

=head2 X

The C<X> accessor provides the location of the actor in metres on the east
to west dimension within the 3D world. The positive direction is east.

=cut

sub X {
	$_[0]->{position}->[0];
}

=pod

=head2 Y

The C<Y> accessor is location of the actor in metres on the vertical
dimension within the 3D world. The positive direction is up.

=cut

sub Y {
	$_[0]->{position}->[1];
}

=pod

=head2 Z

The C<Z> accessor provides the location of the camera in metres on the north
to south dimension within the 3D world. The positive direction is north.

=cut

sub Z {
	$_[0]->{position}->[2];
}

=pod

=head2 position

The C<position> accessor provides the location of the camera as a 3 element
array reference of the structure C<[ X, Y, Z ]>.

=cut

sub position {
	$_[0]->{position};
}





######################################################################
# General Methods

=pod

=head2 box

The C<box> method returns the bounding box for the object if it has one,
relative to the position of the object.

=cut

sub box {
	$_[0]->{box};
}

=pod

=head2 bounding

The C<bounding> method returns the bounding box for the object if it has
one, relative to the world origin.

The default implementation of the C<bounding> method will take the actors
position-relative bounding C<box> and combine it with the relative
C<position> of the actor to get the world-relative box.

=cut

sub bounding {
	my $self     = shift;
	my $position = $self->{position} or return ();
	my $box      = ($self->{box} or $self->box) or return ();

	# Quick version if not scaling
	unless ( $self->{scale} ) {
		return (
			$box->[0] + $position->[0],
			$box->[1] + $position->[1],
			$box->[2] + $position->[2],
			$box->[3] + $position->[0],
			$box->[4] + $position->[1],
			$box->[5] + $position->[2],
		);
	}

	# Full version with scaling support
	my $scale = $self->{scale};
	return (
		$box->[0] * $scale->[0] + $position->[0],
		$box->[1] * $scale->[1] + $position->[1],
		$box->[2] * $scale->[2] + $position->[2],
		$box->[3] * $scale->[0] + $position->[0],
		$box->[4] * $scale->[1] + $position->[1],
		$box->[5] * $scale->[2] + $position->[2],
	);
}





######################################################################
# Engine Interface

sub init {
	my $self = shift;

	# Initialise the material if it has one
	if ( $self->{material} ) {
		$self->{material}->init;
	}

	return 1;
}

sub display {
	my $self = shift;

	# Translate, scale and rotate to the position of the actor
	OpenGL::glTranslatef( @{$self->{position}} );

	# Scale if needed.
	if ( $self->{scale} ) {
		OpenGL::glScalef( @{$self->{scale}} );
	}

	# Rotate if needed
	if ( $self->{orient} ) {
		OpenGL::glRotatef( @{$self->{orient}} );
	}

	return;
}

sub move {
	my $self = shift;
	my $step = shift;

	# If it has velocity, change the actor's position
	$self->{position}->[0] += $self->{velocity}->[0] * $step;
	$self->{position}->[1] += $self->{velocity}->[1] * $step;
	$self->{position}->[2] += $self->{velocity}->[2] * $step;

	# Rotate if we need to
	if ( $self->{orient} and $self->{rotate} ) {
		$self->{orient}->[0] += $self->{rotate} * $step;
	}

	return;
}

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SDL-Tutorial-3DWorld>

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<SDL>, L<OpenGL>

=head1 COPYRIGHT

Copyright 2010 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
