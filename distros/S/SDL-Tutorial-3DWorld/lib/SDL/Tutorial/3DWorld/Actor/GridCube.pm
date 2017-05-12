package SDL::Tutorial::3DWorld::Actor::GridCube;

=pod

=head1 NAME

SDL::Tutorial::3DWorld::Actor::GridCube - A grid-snapping 3D wireframe cube

=head1 DESCRIPTION

The B<GridCube> is a 1 metre white wireframe cube which will track it's
position in float terms and can be moved around the game world like any
other actor, but which will draw itself snapped to an imaginary 1 metre
grid.

The position of the cube will be moved to ensure that the actual floating
point location of the actor is inside the cube.

If the location of the cube is an exact integer, the cube will be located
on the positive axis side (in all three dimension) of the actor position.

=cut

use 5.008;
use strict;
use warnings;
use SDL::Tutorial::3DWorld::OpenGL ();
use SDL::Tutorial::3DWorld::Actor  ();
use OpenGL::List ();

# Use proper POSIX math rather than playing games with Perl's int()
use POSIX ();

our $VERSION = '0.33';
our @ISA     = 'SDL::Tutorial::3DWorld::Actor';

sub new {
	my $self = shift->SUPER::new(@_);

	# Gridcubes need blending
	$self->{blending} = 1;

	return $self;
}





######################################################################
# Engine Interface

sub init {
	my $self = shift;
	$self->SUPER::init(@_);

	# Compile the point and cube lists
	$self->{point_list} = OpenGL::List::glpList {
		$self->compile_point;
	};
	$self->{lines_list} = OpenGL::List::glpList {
		$self->compile_lines;
	};

	return 1;
}

sub display {
	my $self     = shift;
	my $position = $self->{position};

	# Translate to the correct location
	$self->SUPER::display(@_);

	# The cube is plain opaque full-bright white and ignores lighting
	OpenGL::glDisable( OpenGL::GL_LIGHTING );
	OpenGL::glDisable( OpenGL::GL_TEXTURE_2D );

	# Draw a point at the exact X,Y,Z position and reset translation
	OpenGL::glCallList( $self->{point_list} );

	# Translate down to the next lowest integer before drawing the cube
	my @delta = map { POSIX::floor($_) - $_ } @$position;
	OpenGL::glTranslatef( @delta );
	OpenGL::glCallList( $self->{lines_list} );

	# Lighting is on by default in our 3DWorld application.
	# Reenable it so each individual lit object doesn't have to
	# explicitly turn it on.
	OpenGL::glEnable( OpenGL::GL_TEXTURE_2D );
	OpenGL::glEnable( OpenGL::GL_LIGHTING );
	
	return;
}

# The compilable section of the point display logic
sub compile_point {
	OpenGL::glBlendFunc( OpenGL::GL_SRC_ALPHA, OpenGL::GL_ONE_MINUS_SRC_ALPHA );
	OpenGL::glEnable( OpenGL::GL_BLEND );
	OpenGL::glEnable( OpenGL::GL_POINT_SMOOTH );
	OpenGL::glPointSize( 5 );
	OpenGL::glColor4f( 1, 1, 1, 1 );
	OpenGL::glBegin( OpenGL::GL_POINTS );
	OpenGL::glVertex3f( 0, 0, 0 );
	OpenGL::glEnd();
	OpenGL::glDisable( OpenGL::GL_POINT_SMOOTH );
	OpenGL::glDisable( OpenGL::GL_BLEND );
}

# The compilable section of the grid cube display logic
sub compile_lines {
	# Enable line smoothing
	OpenGL::glBlendFunc( OpenGL::GL_SRC_ALPHA, OpenGL::GL_ONE_MINUS_SRC_ALPHA );
	OpenGL::glEnable( OpenGL::GL_BLEND );
	OpenGL::glEnable( OpenGL::GL_LINE_SMOOTH );

	# Draw all the lines in the cube
	OpenGL::glLineWidth(1);
	OpenGL::glColor4f( 1, 1, 1, 1 );
	OpenGL::glBegin( OpenGL::GL_LINES );
	OpenGL::glVertex3f( 0, 0, 0 ); OpenGL::glVertex3f( 1, 0, 0 );
	OpenGL::glVertex3f( 0, 0, 0 ); OpenGL::glVertex3f( 0, 1, 0 );
	OpenGL::glVertex3f( 0, 0, 0 ); OpenGL::glVertex3f( 0, 0, 1 );
	OpenGL::glVertex3f( 1, 0, 0 ); OpenGL::glVertex3f( 1, 1, 0 );
	OpenGL::glVertex3f( 1, 0, 0 ); OpenGL::glVertex3f( 1, 0, 1 );
	OpenGL::glVertex3f( 0, 1, 0 ); OpenGL::glVertex3f( 1, 1, 0 );
	OpenGL::glVertex3f( 0, 1, 0 ); OpenGL::glVertex3f( 0, 1, 1 );
	OpenGL::glVertex3f( 0, 0, 1 ); OpenGL::glVertex3f( 1, 0, 1 );
	OpenGL::glVertex3f( 0, 0, 1 ); OpenGL::glVertex3f( 0, 1, 1 );
	OpenGL::glVertex3f( 1, 1, 0 ); OpenGL::glVertex3f( 1, 1, 1 );
	OpenGL::glVertex3f( 1, 0, 1 ); OpenGL::glVertex3f( 1, 1, 1 );
	OpenGL::glVertex3f( 0, 1, 1 ); OpenGL::glVertex3f( 1, 1, 1 );
	OpenGL::glEnd();

	# Disable line smoothing
	OpenGL::glDisable( OpenGL::GL_LINE_SMOOTH );
	OpenGL::glDisable( OpenGL::GL_BLEND );
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
