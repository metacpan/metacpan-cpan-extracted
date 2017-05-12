package SDL::Tutorial::3DWorld::Skybox;

=pod

=head1 NAME

SDL::Tutorial::3DWorld::Skybox - Better than a uniform sky colour

=head1 DESCRIPTION

A Skybox is a common method for drawing a full photographic background
for a 3D World visible in all directions.

It consists of a large cube with a set of six special pre-rendered
textures that stich together at the edges, creating the appearance of
a large surrounding environment.

For more information on the general concept of a sky box see
L<http://en.wikipedia.org/wiki/Skybox_%28video_games%29>.

This basic implementation takes a directory and looks for six image files
within it called F<north.bmp>, F<south.bmp>, F<east.bmp>, F<west.bmp>,
F<up.bmp> and F<down.bmp>.

The textures are projected onto the cube and uniformly lit, ignoring the
normal lighting model.

The main special effects "trick" to implementing a skybox is that it will
rotate with the rest of the world but match the movements of the camera
so that artifacts in the skybox texture stay the same size regardless of
the movement of the camera (making them appear to be a long way away).

=head1 METHODS

=cut

use 5.008;
use strict;
use warnings;
use File::Spec                      ();
use SDL::Tutorial::3DWorld          ();
use SDL::Tutorial::3DWorld::Camera  ();
use SDL::Tutorial::3DWorld::Texture ();
use SDL::Tutorial::3DWorld::OpenGL  ();
use OpenGL::List                    ();
use OpenGL;

our $VERSION = '0.33';

=pod

=head2 new

  # Load a skybox from a set of files included within a distribution
  my $sky = SDL::Tutorial::3DWorld::Skybox->new(
      directory => File::Spec->catdir(
          File::ShareDir::dist_dir('SDL-Tutorial-3DWorld'), 'skybox'
      )
  );

The C<new> constructor creates a new skybox object.

It takes a single C<directory> parameter which should be a directory that
exists, and contains the six named BMP skybox texture files.

Although the existance of the texture files will be checked at constructor
time, they will not actually be loaded until you run the world (during the
init phase).

=cut

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check params
	my $type      = $self->type;
	my $directory = $self->directory;
	unless ( $type ) {
		die "Missing or invalid skybox texture file type";
	}
	unless ( defined $directory and -d $directory ) {
		die "Missing or invalid skybox texture directory";
	}

	# Locate the five main textures
	foreach my $side ( qw{ north east south west up } ) {
		$self->{$side} = SDL::Tutorial::3DWorld::Texture->new(
			file => File::Spec->catfile(
				$directory, "$side.$type",
			),
		);
	}

	# Many sky boxes don't have a bottom texture, we are ok with that
	local $@;
	$self->{down} = eval {
		SDL::Tutorial::3DWorld::Texture->new(
			file => File::Spec->catfile(
				$directory, "down.$type",
			)
		);
	};

	return $self;
}

=pod

=head2 directory

The C<directory> accessor returns the skybox texture directory.

=cut

sub directory {
	$_[0]->{directory};
}

=pod

=head2 type

The C<type> accessor returns the file type of the skybox textures.

=cut

sub type {
	$_[0]->{type};
}





######################################################################
# Engine Interface

sub init {
	my $self = shift;

	# Initialise all the textures
	foreach my $side ( qw{ north east south west up down } ) {
		$self->{$side}->init if $self->{$side};
	}

	# Compile the display list
	$self->{list} = OpenGL::List::glpList {
			$self->compile;
	};

	return 1;
}

# NOTE: Currently the textures are actually being drawn onto the walls
# backwards. We should put some works on the sky box so we can prove it
# is being drawn on correctly.
sub display {
	my $self   = shift;
	my $camera = SDL::Tutorial::3DWorld->current->camera;

	# To make the skybox special effect work, we move the cube so that
	# it is always centred around the camera.
	glPushMatrix();
	glTranslatef( $camera->X, $camera->Y, $camera->Z );

	# Call the display list
	glCallList( $self->{list} );

	# Exit the special Matrix context the skybox needs to draw in.
	glPopMatrix();

	return 1;
}

# Compilable portion of the display logic
sub compile {
	my $self   = shift;
 
	# Lighting does not apply to the skybox.
	# Reset coloring to white so we don't leak a color from a model.
	glDisable( GL_LIGHTING );
	glEnable( GL_TEXTURE_2D );
	glColor4f( 1, 1, 1, 1 );

	# When drawing the skybox cube, each quad should be slightly larger
	# around than the distance each face is away from the camera.
	# This creates an extremely slight overlap at each edge and prevents
	# visible "seams" on the skybox which otherwise ruin the sky effect.
	# 1.002 is enough to remove these seams, but using 1.1 isn't enough.

	# Draw the north face
	$self->{north}->display;
	glBegin( GL_QUADS );
	glTexCoord2f( 0, 0 ); glVertex3f( -1.002,  1.002, -1 ); # Top Left
	glTexCoord2f( 0, 1 ); glVertex3f( -1.002, -1.002, -1 ); # Bottom Left
	glTexCoord2f( 1, 1 ); glVertex3f(  1.002, -1.002, -1 ); # Bottom Right
	glTexCoord2f( 1, 0 ); glVertex3f(  1.002,  1.002, -1 ); # Top Right
	glEnd();

	# Draw the south face 
	$self->{south}->display;
	glBegin( GL_QUADS );
	glTexCoord2f( 0, 0 ); glVertex3f(  1.002,  1.002,  1 ); # Top Left
	glTexCoord2f( 0, 1 ); glVertex3f(  1.002, -1.002,  1 ); # Bottom Left
	glTexCoord2f( 1, 1 ); glVertex3f( -1.002, -1.002,  1 ); # Bottom Right
	glTexCoord2f( 1, 0 ); glVertex3f( -1.002,  1.002,  1 ); # Top Right
	glEnd();

	# Draw the east face
	$self->{east}->display;
	glBegin( GL_QUADS );
	glTexCoord2f( 0, 0 ); glVertex3f(  1,  1.002, -1.002 ); # Top Left
	glTexCoord2f( 0, 1 ); glVertex3f(  1, -1.002, -1.002 ); # Bottom Left
	glTexCoord2f( 1, 1 ); glVertex3f(  1, -1.002,  1.002 ); # Bottom Right
	glTexCoord2f( 1, 0 ); glVertex3f(  1,  1.002,  1.002 ); # Top Right
	glEnd();

	# Draw the west face
	$self->{west}->display;
	glBegin( GL_QUADS );
	glTexCoord2f( 0, 0 ); glVertex3f( -1,  1.002,  1.002 ); # Top Left
	glTexCoord2f( 0, 1 ); glVertex3f( -1, -1.002,  1.002 ); # Bottom Left
	glTexCoord2f( 1, 1 ); glVertex3f( -1, -1.002, -1.002 ); # Bottom Right
	glTexCoord2f( 1, 0 ); glVertex3f( -1,  1.002, -1.002 ); # Top Right
	glEnd();

	# Draw the ceiling face
	$self->{up}->display;
	glBegin( GL_QUADS );
	glTexCoord2f( 0, 0 ); glVertex3f( -1.002,  1,  1.002 ); # Top Left
	glTexCoord2f( 0, 1 ); glVertex3f( -1.002,  1, -1.002 ); # Bottom Left
	glTexCoord2f( 1, 1 ); glVertex3f(  1.002,  1, -1.002 ); # Bottom Right
	glTexCoord2f( 1, 0 ); glVertex3f(  1.002,  1,  1.002 ); # Top Right
	glEnd();

	# Draw the optional floor
	if ( $self->{down} ) {
		$self->{down}->display;
		glBegin( GL_QUADS );
		glTexCoord2f( 0, 0 ); glVertex3f( -1.002, -1,  1.002 ); # Top Left
		glTexCoord2f( 0, 1 ); glVertex3f( -1.002, -1, -1.002 ); # Bottom Left
		glTexCoord2f( 1, 1 ); glVertex3f(  1.002, -1, -1.002 ); # Bottom Right
		glTexCoord2f( 1, 0 ); glVertex3f(  1.002, -1,  1.002 ); # Top Right
		glEnd();
	}

	# Flush the depth buffer so we can draw the rest of the world.
	# Some tutorials suggest disabling depth buffering but in my experience
	# this still provides some tearing. I prefer to draw the box and then
	# flush the depth buffer instead.
	glClear( GL_DEPTH_BUFFER_BIT );

	# Light is on by default in the 3DWorld tutorial, so setting it
	# back to the default here means every other lit object doesn't
	# need to explicitly turn it on.
	glEnable( GL_LIGHTING );

	return 1;
}

=cut

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
