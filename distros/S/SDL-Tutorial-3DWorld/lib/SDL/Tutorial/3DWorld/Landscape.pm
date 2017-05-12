package SDL::Tutorial::3DWorld::Landscape;

=pod

=head1 NAME

SDL::Tutorial::3DWorld::Landscape - The static 3D environment of the world

=head1 DESCRIPTION

A landscape is the "world" part of the 3D World. It will generally just sit
in the same place, looking pretty (ideally) and doing nothing (mostly).

While it may sometimes change in shape, it certainly does not move around
as a whole.

The B<SDL::Tutorial::3DWorld::Landscape> module is responsible for creating
the world, and updating it if needed.

In this demonstration code, the landscape consists of a simple 50m x 50m
white square.

=head1 METHODS

=cut

use 5.008;
use strict;
use warnings;
use File::Spec                      ();
use File::ShareDir                  ();
use SDL::Tutorial::3DWorld::Texture ();
use OpenGL;

our $VERSION = '0.33';

=pod

=head2 new

The C<new> constructor for the landscape. It takes no parameters and
returns an object representing the static part of the game world.

=cut

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Create a texture handle
	$self->{texture} = SDL::Tutorial::3DWorld::Texture->new(
		file => File::Spec->catfile(
			File::ShareDir::dist_dir('SDL-Tutorial-3DWorld'),
			'chessboard.jpg',
		),
	);

	return $self;
}

=pod

=head2 sky

  my ($red, $green, $blue, $alpha) = $landscape->sky;

The C<sky> method returns the colour of the sky as a four element RGBA list,
with each colour a value in the range 0 to 1.

The sky value is the colour that is used to wipe the OpenGL colour buffer
(the buffer that ultimately becomes what appears on your monitor) and so will
serve effectively as the "background colour" for your world.

This value is not currently configurable, and will always return a dark navy
blue.

=cut

sub sky {
	return ( 0, 0, 0, 1 );
}





######################################################################
# Engine Interface

# Configure the colour that each frame will be cleared with before
# any objects are drawn. This is effectively the "sky" colour.
# We get the colour from the sky method, so that later on this value
# can be configurable.
sub init {
	my $self = shift;

	# Set the universal background colour
	glClearColor( $self->sky );

	# Give everything at least a little light
	OpenGL::glLightModelfv_p( GL_LIGHT_MODEL_AMBIENT, 0.2, 0.2, 0.2, 1 );

	# Load the landscape chessboard texture
	$self->{texture}->init;
}

# Draw a variable colour 20 metre wide flat square at zero height
sub display {
	my $self = shift;

	# Set up the surface material
	$self->{texture}->display;
	OpenGL::glMaterialf( GL_FRONT, GL_SHININESS, 50 );
	OpenGL::glMaterialfv_p( GL_FRONT, GL_SPECULAR, 0.3, 0.3, 0.3, 1 );
	OpenGL::glMaterialfv_p( GL_FRONT, GL_DIFFUSE,  0.7, 0.7, 0.7, 1 );
	OpenGL::glMaterialfv_p( GL_FRONT, GL_AMBIENT,  0.3, 0.3, 0.3, 1 );

	# Draw the platform
	glBegin( GL_QUADS );
	glNormal3f( 0, 1, 0 );
	glTexCoord2f(    0, 1000 ); glVertex3d( -4, 0, -4 ); # Top Left
	glTexCoord2f(    0, 1000 ); glVertex3d( -4, 0,  4 ); # Bottom Left
	glTexCoord2f( 1000, 1000 ); glVertex3d(  4, 0,  4 ); # Bottom Right
	glTexCoord2f( 1000,    0 ); glVertex3d(  4, 0, -4 ); # Top Right
	glEnd();
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
