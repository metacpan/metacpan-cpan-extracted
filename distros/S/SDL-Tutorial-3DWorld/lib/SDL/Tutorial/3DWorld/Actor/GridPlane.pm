package SDL::Tutorial::3DWorld::Actor::GridPlane;

# This implements a static psuedo-3d horizontal plane of cubes (actually
# just the sides of the cube).
#
# When bounded by two flat planes at the top and bottom, the GridPlane
# object should allow you to implement a cube-based grid map as used in
# old games like Wolfenstein 3D.
#
# In the initial implementation this map is completely static, without
# any moving walls or none-perfect cube elements such as doors.
#
# When rendering, we rely on the power of modern graphics cards to brute
# force render the entire map instead of relying on optimisation.

use 5.008;
use strict;
use warnings;
use SDL::Tutorial::3DWorld::OpenGL  ();
use SDL::Tutorial::3DWorld::Actor   ();
use SDL::Tutorial::3DWorld::Bound   ();
use SDL::Tutorial::3DWorld::Texture ();

our $VERSION = '0.33';
our @ISA     = 'SDL::Tutorial::3DWorld::Actor';





######################################################################
# Constructor and Accessors

sub new {
	my $self = shift->SUPER::new(@_);

	# Do we have a texture set 
	unless ( $self->{size} ) {
		die "Did not provide a map size";
	}
	unless ( $self->{wall} ) {
		die "Did not provide a wall texture set";
	}
	unless ( $self->{map} ) {
		die "Did not provide a the map";
	}

	return $self;
}





######################################################################
# Engine Methods

sub init {
	my $self  = shift;
	my $wall  = $self->{wall};
	my $scale = $self->{scale} || [ 1, 1, 1 ];

	# Set up the bounding box
	$self->{bound} = SDL::Tutorial::3DWorld::Bound->box(
		0, 0, 0,
		$scale->[0] * $self->{size},
		$scale->[1] * 1,
		$scale->[2] * $self->{size},
	);

	# Initialise the textures
	foreach my $i ( 0 .. $#$wall ) {
		# Turn off mag filtering for that retro pixel look
		$wall->[$i] = SDL::Tutorial::3DWorld::Texture->new(
			file       => $wall->[$i],
			tile       => 0,
			mag_filter => OpenGL::GL_NEAREST,
		);
		$wall->[$i]->init;
	}

	# Make sure the array position lines up with the map id.
	# That is, the first wall texture is at position 1.
	unshift @$wall, undef;

	# Compile the map into one big display list
	$self->{list} = OpenGL::List::glpList {
		OpenGL::glTranslatef( @{$self->{position}} );
		OpenGL::glScalef(  @{$self->{scale}}  ) if $self->{scale};
		OpenGL::glRotatef( @{$self->{orient}} ) if $self->{orient};
		$self->compile;
	};

	return 1;
}

# Generate the drawing instructions
sub compile {
	my $self  = shift;
	my $size  = $self->{size};
	my $n     = $size - 1;
	my $wall  = $self->{wall};
	my $debug = $self->{debug};

	# Generate a two-dimensional array from the map string
	my @map = map {
		[ split //, $_ ]
	} split /\n/, $self->{map};

	# To be sufficiently old school, we don't do shadows
	OpenGL::glDisable( OpenGL::GL_LIGHTING );

	# Draw the floor of the map
	OpenGL::glDisable( OpenGL::GL_TEXTURE_2D );
	OpenGL::glColor3f( @{$self->{floor}} );
	OpenGL::glBegin( OpenGL::GL_QUADS );
	OpenGL::glVertex3f( 0,     0.001, 0     );
	OpenGL::glVertex3f( 0,     0.001, $size );
	OpenGL::glVertex3f( $size, 0.001, $size );
	OpenGL::glVertex3f( $size, 0.001, 0     );
	OpenGL::glEnd();

	# Draw the roof of the map
	OpenGL::glColor3f( @{$self->{ceiling}} );
	OpenGL::glBegin( OpenGL::GL_QUADS );
	OpenGL::glVertex3f( 0,     1, 0     );
	OpenGL::glVertex3f( $size, 1, 0     );
	OpenGL::glVertex3f( $size, 1, $size );
	OpenGL::glVertex3f( 0,     1, $size );
	OpenGL::glEnd();

	# Prepare to show the textured walls
	OpenGL::glEnable( OpenGL::GL_TEXTURE_2D );
	OpenGL::glColor3f( 1, 1, 1 );

	# Track the active wall texture
	my $active = 0;

	# Iterate through the map
	foreach my $x ( 0 .. $n ) {
		my $X = $x + 1;
		foreach my $z ( 0 .. $n ) {
			my $Z = $z + 1;

			# Ignore open space
			my $w = $map[$x]->[$z] or next;

			# Switch textures if needed
			if ( $w != $active ) {
				OpenGL::glEnd() if $active;
				$wall->[$w]->display;
				$active = $w;
				OpenGL::glBegin( OpenGL::GL_QUADS );
			}

			# Draw the north face unless hidden
			if ( $debug or not $z or not $map[$x]->[$z-1] ) {
				# Top Left
				OpenGL::glTexCoord2f( 0, 0 );
				OpenGL::glVertex3f( $X, 1, $z );

				# Bottom Left
				OpenGL::glTexCoord2f( 0, 1 );
				OpenGL::glVertex3f( $X, 0, $z ); 

				# Bottom Right
				OpenGL::glTexCoord2f( 1, 1 );
				OpenGL::glVertex3f( $x, 0, $z );

				# Top Right
				OpenGL::glTexCoord2f( 1, 0 );
				OpenGL::glVertex3f( $x, 1, $z );
			}

			# Draw the east face unless hidden
			if ( $debug or not $map[$x+1]->[$z] ) {
				# Top Left
				OpenGL::glTexCoord2f( 0, 0 );
				OpenGL::glVertex3f( $X, 1, $Z );

				# Bottom Left
				OpenGL::glTexCoord2f( 0, 1 );
				OpenGL::glVertex3f( $X, 0, $Z ); 

				# Bottom Right
				OpenGL::glTexCoord2f( 1, 1 );
				OpenGL::glVertex3f( $X, 0, $z );

				# Top Right
				OpenGL::glTexCoord2f( 1, 0 );
				OpenGL::glVertex3f( $X, 1, $z );
			}

			# Draw the south face unless hidden
			if ( $debug or not $map[$x]->[$z+1] ) {
				# Top Left
				OpenGL::glTexCoord2f( 0, 0 );
				OpenGL::glVertex3f( $x, 1, $Z );

				# Bottom Left
				OpenGL::glTexCoord2f( 0, 1 );
				OpenGL::glVertex3f( $x, 0, $Z ); 

				# Bottom Right
				OpenGL::glTexCoord2f( 1, 1 );
				OpenGL::glVertex3f( $X, 0, $Z );

				# Top Right
				OpenGL::glTexCoord2f( 1, 0 );
				OpenGL::glVertex3f( $X, 1, $Z );
			}

			# Draw the west face unless hidden
			if ( $debug or not $x or not $map[$x-1]->[$z] ) {
				# Top Left
				OpenGL::glTexCoord2f( 0, 0 );
				OpenGL::glVertex3f( $x, 1, $z );

				# Bottom Left
				OpenGL::glTexCoord2f( 0, 1 );
				OpenGL::glVertex3f( $x, 0, $z ); 

				# Bottom Right
				OpenGL::glTexCoord2f( 1, 1 );
				OpenGL::glVertex3f( $x, 0, $Z );

				# Top Right
				OpenGL::glTexCoord2f( 1, 0 );
				OpenGL::glVertex3f( $x, 1, $Z );
			}
		}
	}

	# Reenable lighting
	OpenGL::glEnd();
	OpenGL::glEnable( OpenGL::GL_LIGHTING );

	return 1;
}

# This should never need to be called
sub display {
	OpenGL::glCallList( $_[0]->{list} );
}

1;
