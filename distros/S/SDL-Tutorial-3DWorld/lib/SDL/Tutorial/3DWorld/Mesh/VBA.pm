package SDL::Tutorial::3DWorld::Mesh::VBA;

# A compiled/optimised ::Mesh using Vertex Buffer Arrays, which are
# optimised in terms calls to GL but hold the data client side.

use 5.008;
use strict;
use warnings;
use OpenGL                         ();
use SDL::Tutorial::3DWorld::OpenGL ();

our $VERSION = '0.33';





######################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# We require at the very least a vertex array
	unless ( defined $self->{vertex} ) {
		die "Did not provide a vertex buffer array";
	}

	return $self;
}

sub vertex {
	$_[0]->{vertex};
}

sub normal {
	$_[0]->{normal};
}





######################################################################
# Engine Methods

sub init {
	return 1;
}

sub display {
	my $self = shift;

	# Assume all the client list pointers are disable by default
	# and enable just the ones we need.
	if ( $self->{vertex} ) {
		OpenGL::glEnableClientState( OpenGL::GL_VERTEX_ARRAY );
	}
	if ( $self->{normal} ) {
		OpenGL::glEnableClientState( OpenGL::GL_NORMAL_ARRAY );
	}
	if ( $self->{color} ) {
		OpenGL::glEnableClientState( OpenGL::GL_COLOR_ARRAY );
	}
	if ( $self->{texture_coord} ) {
		OpenGL::glEnableClientState( OpenGL::GL_TEXTURE_COORD_ARRAY );
	}

	# Draw by index
	my $draw_arrays = $self->{draw_arrays};
	foreach ( @$draw_arrays ) {
		OpenGL::glDrawArrays( $_->[0], $_->[1] );
	}

	# Disable the client state params we use
	if ( $self->{vertex} ) {
		OpenGL::glDisableClientState( OpenGL::GL_VERTEX_ARRAY );
	}
	if ( $self->{normal} ) {
		OpenGL::glDisableClientState( OpenGL::GL_NORMAL_ARRAY );
	}
	if ( $self->{color} ) {
		OpenGL::glDisableClientState( OpenGL::GL_COLOR_ARRAY );
	}
	if ( $self->{texture_coord} ) {
		OpenGL::glDisableClientState( OpenGL::GL_TEXTURE_COORD_ARRAY );
	}

	return 1;
}

1;
