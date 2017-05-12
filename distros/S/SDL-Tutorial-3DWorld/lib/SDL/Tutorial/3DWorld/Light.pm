package SDL::Tutorial::3DWorld::Light;

=pod

=head1 NAME

SDL::Tutorial::3DWorld::Light - A light source in the 3D world

=head1 SYNOPSIS

  # An overhead light at a nice room ceiling height
  my $light = SDL::Tutorial::3DWorld::Light->new(
      X => 0,
      Y => 3.5,
      Z => 0,
  );

=head1 DESCRIPTION

Other than in very simple worlds with intentionally flat colour, most game
worlds are lit by light sources.

Lights may sometimes be seen as part of the landscape in the sense they
are fixed and generally places to best highlight the game world. They can
also sometimes be seen as actors, for example when a light source is used
as a weapon special effect.

However, for the purpose of this tutorial we will treat lights as first
class entities in their own right.

For the purpose of the tutorial only the position of the lighting can be
controlled. All lights will have a fixed colour, intensity, and diffusion.

=head1 METHODS

=cut

use 5.008;
use strict;
use warnings;
use SDL::Tutorial::3DWorld::OpenGL ();
use OpenGL::List                   ();

our $VERSION = '0.33';

=pod

=head2 new

  # A light in the sky at noon
  my $sun = SDL::Tutorial::3DWorld::Light->new(
      X => 0,
      Y => 10000,
      Z => 0,
  );

The C<new> constructor creates a new light source in the 3D world.

In the initial demonstration, only the position of the light is controllable
and the nature of the light source (colour, diffusion etc) is fixed.

=cut

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Defaults and clean up
	$self->{position} ||= [ 0.0, 0.0, 0.0, 1   ];
	$self->{ambient}  ||= [ 0.2, 0.2, 0.2, 1.0 ];
	$self->{diffuse}  ||= [ 1.0, 1.0, 1.0, 1.0 ];
	$self->{specular} ||= [ 1.0, 1.0, 1.0, 1.0 ];
	if ( @{$self->{position}} == 3 ) {
		# Add the weird unused value to comply with the function
		$self->{position}->[3] = 1;
	}

	# OpenGL light operations are special and need special light ids
	unless ( defined $self->{id} ) {
		# NOTE: Yes this is stupid and will break for more than one
		# light, but I'll smarten it up later.
		$self->{id} = OpenGL::GL_LIGHT0;
	}

	return $self;
}

=pod

=head2 X

The C<X> accessor provides the location of the actor in metres on the east
to west dimension within the 3D world. The positive direction is east.

=cut

sub X {
	$_[0]->{position}->{X};
}

=pod

=head2 Y

The C<Y> accessor is location of the actor in metres on the vertical
dimension within the 3D world. The positive direction is up.

=cut

sub Y {
	$_[0]->{position}->{Y};
}

=pod

=head2 Z

The C<Z> accessor provides the actor of the camera in metres on the north
to south dimension within the 3D world. The positive direction is north.

=cut

sub Z {
	$_[0]->{position}->{Z};
}





######################################################################
# Light Properties

sub position {
	@{$_[0]->{position}};
}

sub ambient {
	@{$_[0]->{ambient}};
}

sub diffuse {
	@{$_[0]->{diffuse}};
}

sub specular {
	@{$_[0]->{specular}};
}





######################################################################
# Engine Interface

# Initialise
sub init { 1 }

# Light settings do not appear to work inside of a display list.
# So we need to always do this by hand.
sub display {
	my $self = shift;

	# Define the light
	OpenGL::glEnable( $self->{id} );
	OpenGL::glLightfv_p(
		$self->{id},
		OpenGL::GL_POSITION,
		@{$self->{position}},
	);
	OpenGL::glLightfv_p(
		$self->{id},
		OpenGL::GL_AMBIENT,
		@{$self->{ambient}},
	);
	OpenGL::glLightfv_p(
		$self->{id},
		OpenGL::GL_DIFFUSE,
		@{$self->{diffuse}},
	);
	OpenGL::glLightfv_p(
		$self->{id},
		OpenGL::GL_SPECULAR,
		@{$self->{specular}},
	);
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
