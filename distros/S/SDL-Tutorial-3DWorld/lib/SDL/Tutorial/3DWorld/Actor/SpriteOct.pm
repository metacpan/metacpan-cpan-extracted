package SDL::Tutorial::3DWorld::Actor::SpriteOct;

# A SpriteOct is a set of eight sprites that represent
# a single character facing in a particular direction.
# Each of the sprites displays the character at a particular
# 45 degree offset.
# Combined together, the sprites give the illusion of being
# a full 3D model.

use 5.008;
use strict;
use warnings;
use OpenGL::List                     ();
use SDL::Tutorial::3DWorld           ();
use SDL::Tutorial::3DWorld::OpenGL   ();
use SDL::Tutorial::3DWorld::Texture  ();
use SDL::Tutorial::3DWorld::Material ();
use SDL::Tutorial::3DWorld::Actor    ();

our $VERSION = '0.33';
our @ISA     = 'SDL::Tutorial::3DWorld::Actor';





######################################################################
# Constructor and Accessors

sub new {
	my $self = shift->SUPER::new(
		blending => 1,
		@_,
	);

	# Even though the sprite has a notional direction in
	# which it is facing, this does not impact on the OpenGL
	# "orientation" implemented in the base actor class.
	# As such, we use a totally different variable to hold the
	# direction of the character.
	$self->{angle}    ||= 0;
	$self->{velocity} ||= [ 0, 0, 0 ];

	# Convert the eight sprite texture files to full materials
	$self->{material} = [
		map {
			SDL::Tutorial::3DWorld::Material->new(
				ambient => [ 1, 1, 1, 0.5 ],
				diffuse => [ 1, 1, 1, 0.5 ],
				texture => SDL::Tutorial::3DWorld::Texture->new(
					file       => $_,
					tile       => 0,
					mag_filter => OpenGL::GL_NEAREST,
				),
			),
		} ( @{$self->{texture}} )
	];

	return $self;
}





######################################################################
# Engine Interface Methods

sub init {
	my $self = shift;

	# Load the sprites
	foreach my $material ( @{$self->{material}} ) {
		$material->init;
	}

	# Compile the common drawing code
	$self->{draw} = OpenGL::List::glpList {
		$self->compile;
	};

	return 1;
}

sub display {
	my $self = shift;
	$self->SUPER::display(@_);

	# Rotate towards the camera.
	# This merely serves to ensure the sprite is oriented towards
	# the camera and has no relationship to the direction the
	# actor will APPEAR to be facing relative to the camera.
	OpenGL::glRotatef(
		-SDL::Tutorial::3DWorld->current->camera->{angle},
		0, 1, 0,
	);

	# Select which sprite to display
	my $i = (($self->{angle} + 22.5) / 45) % 8;

	# Switch to the sprite
	$self->{material}->[$i]->display;

	# Draw the sprite quad.
	OpenGL::glCallList( $self->{draw} );
}

sub move {
	my $self = shift;
	my $step = shift;
	$self->{angle} += 1 * $step;
	return 1;
}

sub compile {
	my $self = shift;

	# Draw the sprite quad.
	# The texture seems to wrap a little unless we use the 0.01 here.
	OpenGL::glDisable( OpenGL::GL_LIGHTING );
	OpenGL::glBegin( OpenGL::GL_QUADS );
	OpenGL::glTexCoord2f( 0, 0 ); OpenGL::glVertex3f( -0.5,  1,  0 ); # Top Left
	OpenGL::glTexCoord2f( 0, 1 ); OpenGL::glVertex3f( -0.5,  0,  0 ); # Bottom Left
	OpenGL::glTexCoord2f( 1, 1 ); OpenGL::glVertex3f(  0.5,  0,  0 ); # Bottom Right
	OpenGL::glTexCoord2f( 1, 0 ); OpenGL::glVertex3f(  0.5,  1,  0 ); # Top Right
	OpenGL::glEnd();
	OpenGL::glEnable( OpenGL::GL_LIGHTING );

	return 1;
}

1;
