package SDL::Tutorial::3DWorld::Console;

=pod

=head1 NAME

SDL::Tutorial::3DWorld::Console - A text-mode overlay for the world

=head1 SYNOPSIS

  $world->{console} = SDL::Tutorial::3DWorld::Console->new;

=head1 DESCRIPTION

A C<Console> is a text-mode diagnostic overlay for the world.

It is most commonly used for the display of values like frames per second
count, status, and other diagnostic information. It is not particularly
useful for proper "Heads Up Display" style overlays as the drawing is done
entirely with the glutBitmapCharacter() function.

However it does provide quite a simple and easy way to push general
information to the screen in private or scientific applications, or to
display debugging information in games and such.

This demonstration implementation generates one line of text containing
the frames-per-second cound and displays it at the bottom of the screen.

The main L<SDL::Tutorial::3DWorld> render loop considers the console to
be optional, allowing you to display and hide the console on the fly.

=cut

use 5.008;
use strict;
use warnings;
use Time::HiRes                    ();
use SDL::Tutorial::3DWorld         ();
use SDL::Tutorial::3DWorld::OpenGL ();

our $VERSION = '0.33';

# Turn OpenGL fake "constants" into real compile-time optimised constants
use constant {
	GLUT_BITMAP_9_BY_15 => OpenGL::GLUT_BITMAP_9_BY_15,
};

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	return $self;
}

# This uses GLUT, which we don't have to init ourselves.
sub init {
	return 1;
}

sub display {
	my $self = shift;

	# Special case for the first execution
	unless ( defined $self->{time} ) {
		$self->{fps}   = '...';
		$self->{time}  = Time::HiRes::time();
		$self->{tint}  = int $self->{time};
		$self->{count} = 0;
		return 1;
	}

	# Only update the console text once per second
	$self->{count}++;
	my $t = Time::HiRes::time();
	my $i = int $t;
	if ( $i != $self->{tint} ) {
		# Recalculate the FPS
		my $rate = ($t - $self->{time}) / $self->{count};
		my $fps  = $rate ? (1 / $rate) : 0;
		$self->{fps} = sprintf( '%.1f', $fps );

		# Reset the timer
		$self->{time}  = $t;
		$self->{tint}  = $i;
		$self->{count} = 0;
	}

	# Fetch more values and generate the final text
	my $text = sprintf(
		"FPS: %s", #   Angle: %.1f   Elevation: %.1f",
		$self->{fps},
		# SDL::Tutorial::3DWorld->current->camera->{angle},
		# SDL::Tutorial::3DWorld->current->camera->{elevation},
	);

	# Backup the model-view matrix
	OpenGL::glPushMatrix();
	OpenGL::glLoadIdentity();

	# Switch to the projection matrix
	OpenGL::glMatrixMode( OpenGL::GL_PROJECTION );
	OpenGL::glPushMatrix();
	OpenGL::glLoadIdentity();

	# Set up for 2D writing
	my $world = SDL::Tutorial::3DWorld->current;
	OpenGL::gluOrtho2D( 0, $world->{width}, 0, $world->{height} );

	# Disable textures and lighting
	OpenGL::glDisable( OpenGL::GL_TEXTURE_2D );
	OpenGL::glDisable( OpenGL::GL_LIGHTING );
	OpenGL::glColor4f( 1, 1, 1, 1 );
	OpenGL::glRasterPos2i( 5, 5 );

	# Disable depth testing while rendering so our text doesn't
	# get blanked out by very close objects in the world.
	OpenGL::glDisable( OpenGL::GL_DEPTH_TEST );

	# Draw each character
	foreach ( split //, $text ) {
		OpenGL::glutBitmapCharacter(
			GLUT_BITMAP_9_BY_15,
			ord($_),
		);
	}

	# Restore the projection matrix
	OpenGL::glEnable( OpenGL::GL_DEPTH_TEST );
	OpenGL::glEnable( OpenGL::GL_LIGHTING );
	OpenGL::glPopMatrix();

	# Clean up
	OpenGL::glMatrixMode( OpenGL::GL_MODELVIEW );
	OpenGL::glPopMatrix();

	return 1;
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
