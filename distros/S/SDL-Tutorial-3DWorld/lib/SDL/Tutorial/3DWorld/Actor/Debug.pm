package SDL::Tutorial::3DWorld::Actor::Debug;

use 5.008;
use strict;
use warnings;
use SDL::Tutorial::3DWorld::Bound;
use SDL::Tutorial::3DWorld::Actor  ();
use SDL::Tutorial::3DWorld::OpenGL ();
use OpenGL::List                   ();

our $VERSION = '0.33';
our @ISA     = 'SDL::Tutorial::3DWorld::Actor';

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Do we have a parent?
	unless ( $self->{parent} ) {
		die "Did not provide a parent actor";
	}

	# We blend, but don't move
	$self->{blending} = 0;

	# Ensure our move method is called
	$self->{velocity} = [ 0, 0, 0 ];

	return $self;
}





######################################################################
# Engine Interface

sub init {
	my $self = shift;

	# Generate the cube and axis display lists
	$self->{boxlist} = OpenGL::List::glpList {
		$self->compile_box;
	};
	$self->{axislist} = OpenGL::List::glpList {
		$self->compile_axis;
	};

	# Set our initial position, box and boundary data to that of
	# our parents like our normal per-move sync.
	$self->move;

	return 1;
}

sub move {
	my $self = shift;

	# Update our position and size to that of our parent
	$self->{position} = $self->{parent}->{position};
	$self->{bound}    = $self->{parent}->{bound};
	$self->{box}      = $self->{parent}->{box};
	$self->{orient}   = $self->{parent}->{orient};
	$self->{rotate}   = $self->{parent}->{rotate};

	return 1;
}

sub display {
	my $self     = shift;
	my $position = $self->{position} or return;
	my $bound    = $self->{bound}    or return;

	# Axis lines extend to 20% of the length of an
	# object along a dimension past the edge.
	my $XL = $bound->[BOX_X2] + ($bound->[BOX_X2] - $bound->[BOX_X1]) * 0.2;
	my $YL = $bound->[BOX_Y2] + ($bound->[BOX_Y2] - $bound->[BOX_Y1]) * 0.2;
	my $ZL = $bound->[BOX_Z2] + ($bound->[BOX_Z2] - $bound->[BOX_Z1]) * 0.2;

	# Translate to the model origin and call the axis display list,
	# even if the model doesn't have an actual bounding box.
	# Scale to the bounding box if we have one, or just draw it
	# plain and 1 metre on a side otherwise.
	OpenGL::glPushMatrix();
	OpenGL::glTranslatef( @$position );
	OpenGL::glScalef( $XL, $YL, $ZL );
	OpenGL::glRotatef( @{$self->{orient}} ) if $self->{orient};
	OpenGL::glCallList( $self->{axislist} );
	OpenGL::glPopMatrix();

	# Translate to the negative corner
	OpenGL::glTranslatef( @$position );
	OpenGL::glRotatef( @{$self->{orient}} ) if $self->{orient};
	OpenGL::glTranslatef(
		$bound->[BOX_X1], 
		$bound->[BOX_Y1],
		$bound->[BOX_Z1],
	);

	# Scale so that the resulting 1 metre cube becomes the right size
	OpenGL::glScalef(
		$bound->[BOX_X2] - $bound->[BOX_X1],
		$bound->[BOX_Y2] - $bound->[BOX_Y1],
		$bound->[BOX_Z2] - $bound->[BOX_Z1],
	);

	# Call the display list to render the cube
	OpenGL::glCallList( $self->{boxlist} );
}

sub compile_axis {
	my $self = shift;

	# The axis is plain opaque full-bright and ignores lighting
	OpenGL::glDisable( OpenGL::GL_LIGHTING );
	OpenGL::glDisable( OpenGL::GL_TEXTURE_2D );

	# Enable line smoothing
	#OpenGL::glBlendFunc( OpenGL::GL_SRC_ALPHA, OpenGL::GL_ONE_MINUS_SRC_ALPHA );
	OpenGL::glDisable( OpenGL::GL_BLEND );
	OpenGL::glDisable( OpenGL::GL_LINE_SMOOTH );

	# Draw the (R)ed X Axis
	OpenGL::glLineWidth(1);
	OpenGL::glColor4f( 1.0, 0.0, 0.0, 1.0 );
	OpenGL::glBegin( OpenGL::GL_LINES );
	OpenGL::glVertex3f( 0, 0, 0 );
	OpenGL::glVertex3f( 1.1, 0, 0 );
	OpenGL::glEnd();

	# Draw the (G)reen Y Axis
	OpenGL::glColor4f( 0.0, 1.0, 0.0, 1.0 );
	OpenGL::glBegin( OpenGL::GL_LINES );
	OpenGL::glVertex3f( 0, 0, 0 );
	OpenGL::glVertex3f( 0, 1.1, 0 );
	OpenGL::glEnd();

	# Draw the (B)lue Z Axis
	OpenGL::glColor4f( 0.0, 0.0, 1.0, 1.0 );
	OpenGL::glBegin( OpenGL::GL_LINES );
	OpenGL::glVertex3f( 0, 0, 0 );
	OpenGL::glVertex3f( 0, 0, 1.1 );
	OpenGL::glEnd();

	# Revert the light disable
	OpenGL::glEnable( OpenGL::GL_LIGHTING );
}

sub compile_box {
	my $self = shift;

	# The cube is plain opaque full-bright white and ignores lighting
	OpenGL::glDisable( OpenGL::GL_LIGHTING );
	OpenGL::glDisable( OpenGL::GL_TEXTURE_2D );

	# Enable line smoothing
	#OpenGL::glBlendFunc( OpenGL::GL_SRC_ALPHA, OpenGL::GL_ONE_MINUS_SRC_ALPHA );
	OpenGL::glDisable( OpenGL::GL_BLEND );
	OpenGL::glDisable( OpenGL::GL_LINE_SMOOTH );

	# Draw all the lines in the cube
	OpenGL::glColor4f( 0.5, 1.0, 0.50, 1.0 );
	OpenGL::glLineWidth(1);
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

	# Revert the light disable
	OpenGL::glEnable( OpenGL::GL_LIGHTING );
}

1;
