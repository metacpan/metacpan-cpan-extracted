package SDL::Tutorial::3DWorld::Actor::GridSelect;

use 5.008;
use strict;
use warnings;
use SDL::Tutorial::3DWorld         ();
use SDL::Tutorial::3DWorld::OpenGL ();
use SDL::Tutorial::3DWorld::Actor  ();
use OpenGL::List                   ();

# Use proper POSIX math rather than playing games with Perl's int()
use POSIX ();

our $VERSION = '0.33';
our @ISA     = 'SDL::Tutorial::3DWorld::Actor';

sub new {
	my $self = shift->SUPER::new(@_);

	# Gridcubes need blending
	$self->{blending} = 1;

	# The select box starts 2.5 metres in front of the camera
	$self->{distance} = 5;

	# The select box is a 1 metre cube
	# $self->{box} = [ -0.05, -0.05, -0.05, 1.05, 1.05, 1.05 ];

	# We must have some notional velocity to be considered for movement.
	# This is an artifact of the movement optimisation and a bit of a
	# cludge really.
	$self->{velocity} = [ 0, 0, 0 ];

	return $self;
}





######################################################################
# Engine Interface

sub init {
	my $self = shift;
	$self->SUPER::init(@_);

	# Compile the point and cube lists
	$self->{list} = OpenGL::List::glpList {
		$self->compile;
	};

	return 1;
}

sub move {
	my $self   = shift;
	my $camera = SDL::Tutorial::3DWorld->current->camera;

	# Project the location of the notional point out of the camera
	# to find the camera-relative position of the box.
	my $distance  = $self->{distance};
	my $direction = $camera->{direction};
	my @position  = (
		$distance * $direction->[0],
		$distance * $direction->[1],
		$distance * $direction->[2],
	);

	# Limit the selector position to one unit below the floor
	# for a minecraft-inspired selection effect.
	# When applying the limitation we want to constrain on all
	# three dimensions. This has the effect of making the selected
	# grid position still in front of the camera, which looks more
	# natural than simply moving the selection grid up on the Y axis.
	# Set the Y to a slightly larger value rather than multiplying by
	# the ratio to prevent any floating point issues when we do the
	# POSIX::ceil grid-snapping call later.
	my $lowest_y = 0;
	if ( ($camera->Y + $position[1]) < $lowest_y ) {
		my $have_y = $position[1];
		my $want_y = $lowest_y - $camera->Y;
		my $ratio  = $want_y / $have_y;
		$position[0] *= $ratio;
		$position[1] *= $ratio;
		$position[1] += 0.1;
		$position[2] *= $ratio;
	}

	# Apply the final position to the camera position and snap to the
	# grid on the negative side on all three dimensions, as we will be
	# drawing the grid outwards on the positive side on all three.
	$self->{position} = [
		POSIX::floor( $camera->X + $position[0] ),
		POSIX::floor( $camera->Y + $position[1] ),
		POSIX::floor( $camera->Z + $position[2] ),
	];

	return 1;
}

sub display {
	my $self = shift;

	# Translate to the correct location
	$self->SUPER::display(@_);

	# Draw the 1m cube at the location
	OpenGL::glCallList( $self->{list} );
}

# The compilable section of the grid cube display logic
sub compile {
	# The cube is plain opaque full-bright white and ignores lighting
	OpenGL::glDisable( OpenGL::GL_LIGHTING );
	OpenGL::glDisable( OpenGL::GL_TEXTURE_2D );

	# Enable line smoothing
	OpenGL::glBlendFunc( OpenGL::GL_SRC_ALPHA, OpenGL::GL_ONE_MINUS_SRC_ALPHA );
	OpenGL::glEnable( OpenGL::GL_BLEND );
	OpenGL::glEnable( OpenGL::GL_LINE_SMOOTH );

	# Draw all the lines in the cube
	OpenGL::glLineWidth(1);
	OpenGL::glColor4f( 1.0, 1.0, 1.0, 1.0 );
	OpenGL::glBegin( OpenGL::GL_LINES );
	OpenGL::glVertex3f( -0.001, -0.001, -0.001 ); OpenGL::glVertex3f(  1.001, -0.001, -0.001 );
	OpenGL::glVertex3f( -0.001, -0.001, -0.001 ); OpenGL::glVertex3f( -0.001,  1.001, -0.001 );
	OpenGL::glVertex3f( -0.001, -0.001, -0.001 ); OpenGL::glVertex3f( -0.001, -0.001, 1 );
	OpenGL::glVertex3f(  1.001, -0.001, -0.001 ); OpenGL::glVertex3f(  1.001,  1.001, -0.001 );
	OpenGL::glVertex3f(  1.001, -0.001, -0.001 ); OpenGL::glVertex3f(  1.001, -0.001,  1.001 );
	OpenGL::glVertex3f( -0.001,  1.001, -0.001 ); OpenGL::glVertex3f(  1.001,  1.001, -0.001 );
	OpenGL::glVertex3f( -0.001,  1.001, -0.001 ); OpenGL::glVertex3f( -0.001,  1.001,  1.001 );
	OpenGL::glVertex3f( -0.001, -0.001,  1.001 ); OpenGL::glVertex3f(  1.001, -0.001,  1.001 );
	OpenGL::glVertex3f( -0.001, -0.001,  1.001 ); OpenGL::glVertex3f( -0.001,  1.001,  1.001 );
	OpenGL::glVertex3f(  1.001,  1.001, -0.001 ); OpenGL::glVertex3f(  1.001,  1.001,  1.001 );
	OpenGL::glVertex3f(  1.001, -0.001,  1.001 ); OpenGL::glVertex3f(  1.001,  1.001,  1.001 );
	OpenGL::glVertex3f( -0.001,  1.001,  1.001 ); OpenGL::glVertex3f(  1.001,  1.001,  1.001 );
	OpenGL::glEnd();

	# Disable line smoothing
	OpenGL::glDisable( OpenGL::GL_LINE_SMOOTH );
	OpenGL::glDisable( OpenGL::GL_BLEND );

	# Restore lighting
	OpenGL::glEnable( OpenGL::GL_LIGHTING );
}

1;
