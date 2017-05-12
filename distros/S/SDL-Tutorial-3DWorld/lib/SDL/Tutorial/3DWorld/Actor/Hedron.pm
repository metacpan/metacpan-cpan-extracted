package SDL::Tutorial::3DWorld::Actor::Hedron;

use 5.008;
use strict;
use warnings;
use SDL::Tutorial::3DWorld::Actor  ();
use SDL::Tutorial::3DWorld::Model  ();
use SDL::Tutorial::3DWorld::OpenGL ();
use OpenGL::List                   ();

our $VERSION = '0.33';
our @ISA     = 'SDL::Tutorial::3DWorld::Actor';





######################################################################
# Constructors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Do we have the required params
	unless ( $self->{vertex} ) {
		die "Did not provide a vertex list";
	}
	unless ( $self->{actor} ) {
		die "Did not provide a child actor";
	}

	# Scaling is a bit complicated for this model at the moment
	if ( $self->{scale} ) {
		die "Hedron actors do not support scaling";
	}

	return $self;
}

sub icosahedron {
	my $class = shift;
	my $self  = bless {
		vertex => [

			# These are subtly wrong but close enough
			[  0,  0   ],
			[  60, 36  ],
			[  60, 108 ],
			[  60, 180 ],
			[  60, 252 ],
			[  60, 324 ],
			[ 120, 0   ],
			[ 120, 72  ],
			[ 120, 144 ],
			[ 120, 216 ],
			[ 120, 288 ],
			[ 180, 0,  ],
		],
		@_,
	}, $class;

	# Do we have a child actor?
	unless ( $self->{actor} ) {
		die "Did not provide a child actor object";
	}

	return $self;
}





######################################################################
# Engine Methods

sub init {
	my $self = shift;

	# Initialise the child
	$self->{actor}->init;

	# If the child can be fully compiled, compile the entire
	# hedron down to a single display list as well.
	if ( $self->{actor}->{display} and not $self->{velocity} ) {
		$self->{display} = OpenGL::List::glpList {
			OpenGL::glPushMatrix();
			$self->display;
			OpenGL::glPopMatrix();
		};
	}

	return 1;
}

sub display {
	my $self = shift;
	$self->SUPER::display(@_);

	# Rotate to each of the vertice in the hedron and
	# draw the child actor.
	foreach my $rotate ( @{$self->{vertex}} ) {
		# Draw the actor at the offset angle
		OpenGL::glPushMatrix();
		OpenGL::glRotatef( $rotate->[1], 0, 1, 0 );
		OpenGL::glRotatef( $rotate->[0], 1, 0, 0 );
		$self->{actor}->display;
		OpenGL::glPopMatrix();
	}

	return 1;
}

1;
