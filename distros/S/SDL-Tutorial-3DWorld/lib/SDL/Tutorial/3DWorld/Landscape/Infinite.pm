package SDL::Tutorial::3DWorld::Landscape::Infinite;

=pod

=head1 NAME

SDL::Tutorial::3DWorld::Landscape::Infinite - An infinite ground plane

=head1 DESCRIPTION

In many basic or primitive 3D worlds the ground is implemented as a single
infinite plane at zero height.

This type of ground structure greatly simplies many aspects of a world
implementation as we don't need to implement full vertical collision detection.

=head1 METHODS

=cut

use 5.008;
use strict;
use warnings;
use Params::Util                      ();
use SDL::Tutorial::3DWorld::OpenGL    ();
use SDL::Tutorial::3DWorld::Landscape ();

our $VERSION = '0.33';
our @ISA     = 'SDL::Tutorial::3DWorld::Landscape';

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Convert the texture parameter to a texture object
	unless ( Params::Util::_INSTANCE($self->{texture}, 'SDL::Tutorial::3DWorld::Texture') ) {
		$self->{texture} = SDL::Tutorial::3DWorld::Texture->new(
			file => $self->{texture},
		);
	}

	return $self;
}

sub init {
	my $self = shift;
	$self->SUPER::init(@_);

	# Set the universal background colour
	OpenGL::glClearColor( $self->sky );

	# Give everything at least a little light
	OpenGL::glLightModelfv_p( OpenGL::GL_LIGHT_MODEL_AMBIENT, 0.5, 0.5, 0.5, 1 );

	$self->{texture}->init;
	return 1;
}

sub display {
	my $self = shift;
	my $size = 1000;
	my $tile = 3;

	# Calculate the geometry boundaries
	my $vpos = $size / 2;
	my $vneg = -$vpos;

	# Calculate the texture boundaries
	my $tpos = $vpos / $tile;
	my $tneg = $vneg / $tile;

	# Set up the surface material
	$self->{texture}->display;
	OpenGL::glMaterialfv_p( OpenGL::GL_FRONT, OpenGL::GL_AMBIENT,   0.7, 0.7, 0.7, 1 );
	OpenGL::glMaterialfv_p( OpenGL::GL_FRONT, OpenGL::GL_DIFFUSE,   0.7, 0.7, 0.7, 1 );
	OpenGL::glMaterialfv_p( OpenGL::GL_FRONT, OpenGL::GL_SPECULAR,  0.0, 0.0, 0.0, 1 );
	OpenGL::glMaterialf(    OpenGL::GL_FRONT, OpenGL::GL_SHININESS, 127              );

	# Draw the the "infinite" plane, placing it 1/10th of a mm below zero, so that
	# any other surfaces at zero height will be visible about the ground plane.
	# Spread the texture across the entire plane to start with.
	OpenGL::glBegin( OpenGL::GL_QUADS );
	OpenGL::glNormal3f( 0, 1, 0 );
	OpenGL::glTexCoord2f( $tneg, $tneg ); OpenGL::glVertex3d( $vneg, -0.0001, $vneg ); # Top Left
	OpenGL::glTexCoord2f( $tneg, $tpos ); OpenGL::glVertex3d( $vneg, -0.0001, $vpos ); # Bottom Left
	OpenGL::glTexCoord2f( $tpos, $tpos ); OpenGL::glVertex3d( $vpos, -0.0001, $vpos ); # Bottom Right
	OpenGL::glTexCoord2f( $tpos, $tneg ); OpenGL::glVertex3d( $vpos, -0.0001, $vneg ); # Top Right
	OpenGL::glEnd();
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
