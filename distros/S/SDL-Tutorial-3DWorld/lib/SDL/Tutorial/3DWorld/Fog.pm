package SDL::Tutorial::3DWorld::Fog;

# A small convenience encapsulation for basic OpenGL fog

use 5.008;
use strict;
use warnings;
use SDL::Tutorial::3DWorld::OpenGL ();

our $VERSION = '0.33';





######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless {

		# Defaults to match the OpenGL spec
		mode      => OpenGL::GL_LINEAR,
		density   => 1,
		start     => 0,
		end       => 1,
		color     => [ 0.0, 0.0, 0.0, 0.0 ],
		coord_src => OpenGL::GL_FRAGMENT_DEPTH,

		@_,
	}, $class;
	return $self;
}





######################################################################
# Engine Methods

sub init {
	return 1;
}

sub enable {
	my $self = shift;

	# Apply all fog settings
	OpenGL::glFogi( OpenGL::GL_FOG_MODE,      $self->{mode}      );
	OpenGL::glFogi( OpenGL::GL_FOG_COORD_SRC, $self->{coord_src} );
	OpenGL::glFogf( OpenGL::GL_FOG_DENSITY,   $self->{density}   );
	OpenGL::glFogf( OpenGL::GL_FOG_START,     $self->{start}     );
	OpenGL::glFogf( OpenGL::GL_FOG_END,       $self->{end}       );
	OpenGL::glFogfv_p( OpenGL::GL_FOG_COLOR,  @{$self->{color}}  );

	OpenGL::glEnable( OpenGL::GL_FOG );
}

sub disable {
	OpenGL::glDisable( OpenGL::GL_FOG );
}

1;
