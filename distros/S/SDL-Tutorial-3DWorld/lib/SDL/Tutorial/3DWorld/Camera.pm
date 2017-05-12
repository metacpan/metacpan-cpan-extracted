package SDL::Tutorial::3DWorld::Camera;

=pod

=head1 NAME

SDL::Tutorial::3DWorld::Camera - A movable viewpoint in the game world

=head1 SYNOPSIS

  # Start the camera 1.5 metres above the ground, 10 metres back from
  # the world origin, looking north and slightly downwards.
  my $camera = SDL::Tutorial::3DWorld::Camera->new(
      X         => 0,
      Y         => 1.5,
      Z         => 10,
      angle     => 0,
      elevation => -5,
  };

=head1 DESCRIPTION

The B<SDL::Tutorial::3DWorld::Camera> represents the viewpoint that the
user controls to move through the 3D world.

In this initial skeleton code, the camera is fixed and cannot be moved.

=head1 METHODS

=cut

use 5.008;
use strict;
use warnings;
use SDL::Mouse                     ();
use SDL::Constants                 ();
use SDL::Tutorial::3DWorld::OpenGL ();
use SDL::Tutorial::3DWorld::Bound; # Import constants

our $VERSION = '0.33';

use constant {
	D2R  => CORE::atan2(1,1) / 45,
	ZFAR => 100,
};

=pod

=head2 new

  # Start the camera at the origin, facing north and looking at the horizon
  my $camera = SDL::Tutorial::3DWorld::Camera->new(
      X         => 0,
      Y         => 0,
      Z         => 0,
      angle     => 0,
      elevation => 0,
  };

The C<new> constructor creates a camera that serves as the primary
abstraction for the viewpoint as it moves through the world.

=cut

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# The default position of the camera is at 0,0,0 facing north
	$self->{X}          ||= 0;
	$self->{Y}          ||= 0;
	$self->{Z}          ||= 0;
	$self->{angle}      ||= 0;
	$self->{elevation}  ||= 0;
	$self->{speed}      ||= 0.2;

	# The field of view and frustrum properties
	$self->{width}      ||= 1024;
	$self->{height}     ||= 768;
	$self->{aspect}     ||= $self->{width} / $self->{height};
	$self->{fovy}       ||= 45;
	$self->{fovx}       ||= $self->{fovy} * $self->{aspect};
	$self->{znear}        = 0.1 unless defined $self->{znear};
	$self->{zfar}       ||= ZFAR;

	# Preconvert stuff to radians
	$self->{fovyr}      ||= $self->{fovy}      * D2R;
	$self->{fovxr}      ||= $self->{fovx}      * D2R;
	$self->{angler}     ||= $self->{angle}     * D2R;
	$self->{elevationr} ||= $self->{elevation} * D2R;

	# Set up the direction vector for the first time.
	# Update the direction vector we use for variety of tasks.
	# For angle = 0, elevation = 0 this should be 0, 0, -1
	my $angler     = $self->{angler};
	my $elevationr = $self->{elevationr};
	my $direction  = $self->{direction} = [
		sin($angler) * cos($elevationr),
		sin($elevationr),
		-cos($angler) * cos($elevationr),
	];

	# Calculate the frustrum properties.
	# In the original C implementation hfar is calculated with tan() but
	# since Perl doesn't have a native one we use sin/cos. :(
	$self->{dlength} = $self->{zfar} - $self->{znear};
	$self->{dsphere} = $self->{znear} + ($self->{dlength} * 0.5);
	$self->{hfar}    = $self->{dlength}
	                 * sin($self->{fovyr} * 0.5)
	                 / cos($self->{fovyr} * 0.5);
	$self->{wfar}    = $self->{hfar} * $self->{aspect};

	# Find the vector from the near/far halfway point (P)
	# and the far corner of the frustrum (Q).
	my @P = ( 0,             0,             $self->{dsphere} );
	my @Q = ( $self->{wfar}, $self->{hfar}, $self->{dlength} );
	my @D = ( $P[0] - $Q[0], $P[1] - $Q[1], $P[2] - $Q[2]    );

	# The frustrum sphere radius is the length of the vector,
	# and the centre is the camera position plus the length of the centre
	# in the direction the camera is looking.
	$self->{rsphere} = sqrt( $D[0] ** 2 + $D[1] ** 2 + $D[2] ** 2 );
	$self->{xsphere} = $self->{dsphere} * $direction->[0];
	$self->{ysphere} = $self->{dsphere} * $direction->[1];
	$self->{zsphere} = $self->{dsphere} * $direction->[2];

	# Calculate the mouse origin position
	$self->{mouse} = [
		int( $self->{width}  / 2 ),
		int( $self->{height} / 2 ),
	];

	# Key tracking
	$self->{down} = {};

	return $self;
}

=pod

=head2 X

The C<X> accessor provides the location of the camera in metres on the east
to west dimension within the 3D world. The positive direction is east.

=cut

sub X {
	$_[0]->{X};
}

=pod

=head2 Y

The C<Y> accessor is location of the camera in metres on the vertical
dimension within the 3D world. The positive direction is up.

=cut

sub Y {
	$_[0]->{Y};
}

=pod

=head2 Z

The C<Z> accessor provides the location of the camera in metres on the north
to south dimension within the 3D world. The positive direction is north.

=cut

sub Z {
	$_[0]->{Z};
}

=pod

=head2 angle

The C<angle> accessor provides the direction the camera is facing on the
horizontal plane within the 3D world. Positive indicates clockwise degrees
from north. Thus C<0> is north, C<90> is east, C<180> is south and C<270>
is west.

The C<angle> is more correctly known as the "azimuth" but we prefer the
simpler common term for a gaming API. For more details see
L<http://en.wikipedia.org/wiki/Azimuth>.

=cut

sub angle {
	$_[0]->{angle};
}

=pod

=head2 elevation

The C<elevation> accessor provides the direction the camera is facing on
the vertical plane. Positive indicates degrees above the horizon. Thus
C<0> is looking at the horizon, C<90> is facing straight up, and
C<-90> is facing straight down.

The C<elevation> is more correctly known as the "altitude" but we prefer the
simpler common term for a gaming API. For more details see
see L<http://en.wikipedia.org/w/index.php?title=Altitude_(astronomy)>.

=cut

sub elevation {
	$_[0]->{elevation};
}

=pod

=head2 direction

The C<direction> accessor provides a unitised geometric vector for where
the camera is currently pointing. This vector does not have a rotational
component so for any math requiring rotation you will need to naively
assume that the camera rotational orientation is zero (i.e. when looking
at the horizon camera up is geometric up along the positive Y axis)

=cut

sub direction {
	$_[0]->{direction};
}





######################################################################
# Engine Interface

# Note that this doesn't position the camera, just sets it up
sub init {
	my $self = shift;

	# As a mouselook game, we don't want users to see the cursor.
	# We also position the cursor at the exact centre of the window.
	# (This will result in another spurious mouse event)
	SDL::Mouse::show_cursor( SDL::Constants::SDL_DISABLE );
	SDL::Mouse::warp_mouse( @{$self->{mouse}} );

	# Select and reset the projection, flushing any old state
	OpenGL::glMatrixMode( OpenGL::GL_PROJECTION );
	OpenGL::glLoadIdentity();

	# Set the perspective we will look through.
	# We'll use a standard 60 degree perspective, removing any
	# shapes closer than one metre or further than one kilometre.
	OpenGL::gluPerspective(
		$self->{fovy},
		$self->{aspect},
		$self->{znear},
		$self->{zfar},
	);

	# Work super hard to make perspective calculations not suck
	OpenGL::glHint(
		OpenGL::GL_PERSPECTIVE_CORRECTION_HINT,
		OpenGL::GL_NICEST,
	);

	return;
}

sub display {
	my $self = shift;

	# Transform the location of the entire freaking world in the opposite
	# direction and angle to where the camera is and which way it is
	# pointing. This makes it LOOK as if the camera is moving but it isn't.
	OpenGL::glRotatef( $self->{elevation}, -1, 0, 0 );
	OpenGL::glRotatef( $self->{angle},      0, 1, 0 );
	OpenGL::glTranslatef( -$self->{X}, -$self->{Y}, -$self->{Z} );

	return;
}

sub move {
	my $self  = shift;
	my $step  = shift;
	my $down  = $self->{down};
	my $speed = $self->{speed} * $step;

	# Find the camera-wards and sideways components of our velocity
	my $move = $speed * (
		$down->{SDL::Constants::SDLK_s} -
		$down->{SDL::Constants::SDLK_w}
	);
	my $strafe = $speed * (
		$down->{SDL::Constants::SDLK_d} -
		$down->{SDL::Constants::SDLK_a}
	);

	# Apply this movement in the direction of the camera
	my $angler = $self->{angler};
	$self->{X} += (cos($angler) * $strafe) - (sin($angler) * $move);
	$self->{Z} += (sin($angler) * $strafe) + (cos($angler) * $move);

	return;
}

sub event {
	my $self  = shift;
	my $event = shift;
	my $type  = $event->type;

	if ( $type == SDL::Constants::SDL_MOUSEMOTION ) {
		# Ignore mouse motion events at the mouse origin
		$event->motion_x == $self->{mouse}->[0] and
		$event->motion_y == $self->{mouse}->[1] and
		return 1;

		# Convert the mouse motion to mouselook behaviour
		my $x = $event->motion_xrel;
		my $y = $event->motion_yrel;
		$x = $x - 65536 if $x > 32000;
		$y = $y - 65536 if $y > 32000;
		my $angle  = $self->{angle} = ($self->{angle} + $x / 5) % 360;
		$self->{elevation} -= $y / 10;
		$self->{elevation}  =  90 if $self->{elevation} >  90;
		$self->{elevation}  = -90 if $self->{elevation} < -90;

		# Update the direction vector we use for variety of tasks.
		# For angle = 0, elevation = 0 this should be 0, 0, -1
		my $angler     = $self->{angler}     = D2R * $angle;
		my $elevationr = $self->{elevationr} = D2R * $self->{elevation};
		my @direction  = (
			sin($angler) * cos($elevationr),
			sin($elevationr),
			-cos($angler) * cos($elevationr),
		);
		$self->{direction} = \@direction;

		# Update the frustrum sphere centre
		$self->{xsphere} = $self->{X} + ($self->{dsphere} * $direction[0]);
		$self->{ysphere} = $self->{Y} + ($self->{dsphere} * $direction[1]);
		$self->{zsphere} = $self->{Z} + ($self->{dsphere} * $direction[2]);

		# Move the mouse back to the centre of the window so that
		# it can never escape the game window.
		SDL::Mouse::warp_mouse( @{$self->{mouse}} );

		return 1;
	}

	if ( $type == SDL::Constants::SDL_KEYDOWN ) {
		my $key = $event->key_sym;
		if ( exists $self->{down}->{$key} ) {
			$self->{down}->{$key} = 1;
			return 1;
		}
	}

	if ( $type == SDL::Constants::SDL_KEYUP ) {
		my $key = $event->key_sym;
		if ( exists $self->{down}->{$key} ) {
			$self->{down}->{$key} = 0;
			return 1;
		}
	}

	# We don't care about this event
	return 0;
}





######################################################################
# Support Methods

# Sort a series of vectors by distance from the camera, returning
# the result as a list of index positions.
sub distance_isort {
	my $self = shift;
	my $X    = $self->{X};
	my $Y    = $self->{Y};
	my $Z    = $self->{Z};

	# Calculate the distances
	my @distance = map {
		($X - $_->[0]) ** 2 + ($Y - $_->[1]) ** 2 + ($Z - $_->[2]) ** 2
	} @_;

	# Sort index by distance
	my @order = sort {
		$distance[$b] <=> $distance[$a]
	} ( 0 .. $#_ );

	return @order;
}

1;

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