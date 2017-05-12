package SDL::Tutorial::3DWorld;

=pod

=head1 NAME

SDL::Tutorial::3DWorld - Create a 3D world from scratch with SDL and OpenGL

=head1 DESCRIPTION

This tutorial is intended to demonstrate the creation of a trivial but
relatively usable "3D Game Engine".

The demonstration code provided implements the four main elements of a
basic three-dimensional game world.

=over

=item *

A static landscape in which events will occur.

=item *

A light source to illuminate the world.

=item *

A collection of N objects which move around independantly inside the
world.

=item *

A user-controlled mobile camera through which the world is viewed

=back

Each element of the game world is encapsulated inside a standalone class.

This lets you see which parts of the Open GL operations are used to work
with each element of the game world, and provides a starting point from
which you can start to make your own simple game-specific engines.

=head1 METHODS

=cut

use 5.008005;
use strict;
use warnings;
use IO::File                                  1.14 ();
use File::Spec                                3.31 ();
use File::ShareDir                            1.02 ();
use List::MoreUtils                           0.22 ();
use Params::Util                              1.00 ();
use OpenGL                                    0.64 ':all';
use OpenGL::List                              0.01 ();
use SDL                                      2.527 ':all';
use SDL::Event                                     ':all';
use SDLx::App                                      ();
use SDL::Tutorial::3DWorld::Actor                  ();
use SDL::Tutorial::3DWorld::Actor::Billboard       ();
use SDL::Tutorial::3DWorld::Actor::Debug           ();
use SDL::Tutorial::3DWorld::Actor::GridCube        ();
use SDL::Tutorial::3DWorld::Actor::GridPlane       ();
use SDL::Tutorial::3DWorld::Actor::GridSelect      ();
use SDL::Tutorial::3DWorld::Actor::Hedron          ();
use SDL::Tutorial::3DWorld::Actor::MaterialSampler ();
use SDL::Tutorial::3DWorld::Actor::Model           ();
use SDL::Tutorial::3DWorld::Actor::Sprite          ();
use SDL::Tutorial::3DWorld::Actor::SpriteOct       ();
use SDL::Tutorial::3DWorld::Actor::Teapot          ();
use SDL::Tutorial::3DWorld::Actor::TextureCube     ();
use SDL::Tutorial::3DWorld::Actor::TronBit         ();
# use SDL::Tutorial::3DWorld::Actor::TV              ();
use SDL::Tutorial::3DWorld::Asset                  ();
use SDL::Tutorial::3DWorld::Camera                 ();
use SDL::Tutorial::3DWorld::Camera::God            ();
use SDL::Tutorial::3DWorld::Console                ();
use SDL::Tutorial::3DWorld::Fog                    ();
use SDL::Tutorial::3DWorld::Landscape              ();
use SDL::Tutorial::3DWorld::Landscape::Infinite    ();
use SDL::Tutorial::3DWorld::Light                  ();
use SDL::Tutorial::3DWorld::Material               ();
use SDL::Tutorial::3DWorld::Model                  ();
use SDL::Tutorial::3DWorld::OpenGL                 ();
use SDL::Tutorial::3DWorld::Skybox                 ();
use SDL::Tutorial::3DWorld::Texture                ();
use SDL::Tutorial::3DWorld::Bound;

# Enable GLUT support so we can have teapots and other things
BEGIN {
	OpenGL::glutInit();
}

our $VERSION = '0.33';

# The currently active world
our $CURRENT = undef;

=pod

=head2 new

The C<new> constructor sets up the model for the 3D World, but does not
initiate or start the game itself.

It does not current take any parameters.

=cut

sub new {
	my $class = shift;

	# Are we doing a benchmarking run?
	# If so set the flag and we will abort after 100 seconds.
	my $benchmark = scalar grep { $_ eq '--benchmark' } @_;

	# Create the basic object
	my $self  = bless {
		ARGV           => [ @_ ],
		width          => 1280,
		height         => 1024,
		dt             => 0.1,

		# Debugging or expensive elements we can toggle off.
		# Turning all of these three off gives us a much more
		# accurate assessment on how fast a real world would perform.
		benchmark      => $benchmark,
		hide_debug     => $benchmark ? 1 : 0,
		hide_console   => $benchmark ? 1 : 0,
		hide_expensive => $benchmark ? 1 : 0,
	}, $class;

	# Normally we want fullscreen, but occasionally we might want to
	# disable it because we are on a portrait-orientation monitor
	# or for unobtrusive testing (or it doesn't work on some machine).
	# When showing in a window, drop the size to the window isn't huge.
	$self->{fullscreen} = not grep { $_ eq '--window' } @_;
	unless ( $self->{fullscreen} ) {
		$self->{width}  /= 2;
		$self->{height} /= 2;
	}

	# Text console that overlays the world
	$self->{console} = SDL::Tutorial::3DWorld::Console->new;

	# A pretty skybox background for our world
	$self->{skybox} = SDL::Tutorial::3DWorld::Skybox->new(
		type      => 'jpg',
		directory => $self->sharedir('skybox'),
	);

	# Light the world with a single overhead light
	# that matches the position of the sun.
	$self->{lights} = [
		SDL::Tutorial::3DWorld::Light->new(
			position => [ 360, 405, -400 ],
		),
	];

	# Create the (optional) fog.
	# Because it doesn't really blend with the current skybox,
	# I've tweaked it to try to look like a light ground haze.
	# $self->{fog} = SDL::Tutorial::3DWorld::Fog->new(
		# color => [ 0.5, 0.5, 0.5, 0 ],
		# start => 10.0,
		# end   => 50.0,
	# );

	# Create the landscape
	$self->{landscape} = SDL::Tutorial::3DWorld::Landscape::Infinite->new(
		texture => $self->sharefile('ground.jpg'),
	);

	# Place the camera at a typical eye height a few metres back
	# from the teapots and facing slightly down towards them.
	$self->{camera} = SDL::Tutorial::3DWorld::Camera::God->new(
		# Camera position properties
		X      => 0.0,
		Y      => 1.5,
		Z      => 5.0,
		speed  => $self->dscalar(2),

		# Camera view properties
		height => $self->{height},
		width  => $self->{width},
		fovy   => 45,

		# Actor list and indexes for faster culling
		actors => [ ],
		show   => [ ],
		move   => [ ],
	);

	# The selector is an actor and a special camera tool for
	#(potentially) controlling something in the world.
	$self->{selector} = $self->actor(
		SDL::Tutorial::3DWorld::Actor::GridSelect->new,
	);

	# Add a video screen
	# $self->actor(
		# SDL::Tutorial::3DWorld::Actor::TV->new(
			# position => [ 0, 1, -5 ],
			# file     => $self->sharefile('test-mpeg.mpg'),
		# ),
	# );

	# Create the wolfenstein-inspired level
	$self->actor(
		SDL::Tutorial::3DWorld::Actor::GridPlane->new(
			# The GridPlane automatically culls faces that will
			# never be exposed to reduce costs. Turn on this
			# debug flag to always render all faces.
			# debug    => 1,
			position => [ 10, 0, 10 ],
			scale    => 3,
			size     => 9,
			floor    => [ 0.5, 0.5, 0.5 ],
			ceiling  => [ 0.2, 0.2, 0.2 ],
			wall     => [
				$self->sharefile('wall1.png'),
				$self->sharefile('wall2.png'),
				$self->sharefile('wall3.png'),
				$self->sharefile('wall4.png'),
			],
			map      => <<'END_MAP'
112121211
100000003
100000303
100000303
000000303
100330303
100330303
100000303
112121333
END_MAP
		),
	);

	# A full and complex character
	$self->{bit} = $self->actor(
		SDL::Tutorial::3DWorld::Actor::TronBit->new(
			position => [ 1.0, 1.9, 7.0 ],
		),
	);

	# Add three teapots to the scene.
	# (R)ed is the official colour of the X axis.
	$self->actor(
		SDL::Tutorial::3DWorld::Actor::Teapot->new(
			hidden   => $self->{hide_expensive},
			size     => 0.20,
			position => [ 0.0, 0.5, 0.0 ],
			velocity => $self->dvector( 0.1, 0.0, 0.0 ),
			material => {
				ambient   => [ 0.5, 0.2, 0.2, 1.0 ],
				diffuse   => [ 1.0, 0.7, 0.7, 1.0 ],
				specular  => [ 1.0, 1.0, 1.0, 1.0 ],
				shininess => 80,
			},
		),
	);

	# (B)lue is the official colour of the Z axis.
	$self->actor(
		SDL::Tutorial::3DWorld::Actor::Teapot->new(
			hidden   => $self->{hide_expensive},
			size     => 0.30,
			position => [ 0.0, 1.0, 0.0 ],
			velocity => $self->dvector( 0.0, 0.0, 0.1 ),
			material => {
				ambient   => [ 0.2, 0.2, 0.5, 1.0 ],
				diffuse   => [ 0.7, 0.7, 1.0, 1.0 ],
				specular  => [ 1.0, 1.0, 1.0, 1.0 ],
				shininess => 100,
			},
		),
	);

	# (G)reen is the official colour of the Y axis
	$self->actor(
		SDL::Tutorial::3DWorld::Actor::Teapot->new(
			hidden   => $self->{hide_expensive},
			size     => 0.50,
			position => [ 0.0, 1.5, 0.0 ],
			velocity => $self->dvector( 0.0, 0.1, 0.0 ),
			material => {
				ambient   => [ 0.2, 0.5, 0.2, 1.0 ],
				diffuse   => [ 0.7, 1.0, 0.7, 1.0 ],
				specular  => [ 1.0, 1.0, 1.0, 1.0 ],
				shininess => 120,
			},
		),
	);

	# Place a static grid cube in the air on the positive
	# and negative corners of the landscape, proving the
	# grid-bounding math works (which it might not on the
	# negative side of an axis if you mistakenly use int()
	# for the math instead of something like POSIX::ceil/floor).
	$self->actor(
		SDL::Tutorial::3DWorld::Actor::GridCube->new(
			position => [ -3.7, 1.3, -3.7 ],
		),
	);

	# Set up a flying grid cube heading away from the teapots.
	# This should demonstrate the "grid" nature of the cube,
	# and the flying path will take us along a path that will
	# share an edge with the static box, which should look neat.
	$self->actor(
		SDL::Tutorial::3DWorld::Actor::GridCube->new(
			position => [ -0.33, 0.01, -0.66 ],
			velocity => $self->dvector( -0.1, 0.1, -0.1 ),
		),
	);

	# Place a typical large crate on the opposite side of the
	# chessboard from the static gridcube.
	$self->actor(
		SDL::Tutorial::3DWorld::Actor::TextureCube->new(
			size     => 1.3,
			position => [ 3.3, 0.0, 3.35 ],
			material => {
				ambient => [ 0.5, 0.5, 0.5, 1 ],
				texture => $self->sharefile('crate1.jpg'),
			},
		),
	);

	# Place a high-detail table (to test large models and scaling)
	$self->actor(
		SDL::Tutorial::3DWorld::Actor::Model->new(
			scale    => 0.05,
			position => [ -10, 0, 0 ],
			velocity => [   0, 0, 0 ],
			file     => File::Spec->catfile('model', 'table', 'table.obj'),
			plain    => 1,
		),
	);

	# Place a lollipop near the origin to test transparency in models
	$self->actor(
		SDL::Tutorial::3DWorld::Actor::Model->new(
			position => [ -2, 0, 0 ],
			file     => File::Spec->catfile('model', 'lollipop', 'hflollipop1gr.rwx'),
		),
	);

	# Place two nutcrackers a little further away
	$self->actor(
		SDL::Tutorial::3DWorld::Actor::Model->new(
			position => [ -2, 0, -2 ],
			file     => File::Spec->catfile('model', 'nutcracker', "sv-nutcracker1.rwx"),
		),
	);
	$self->actor(
		SDL::Tutorial::3DWorld::Actor::Model->new(
			position => [ -4, 0, -2 ],
			file     => File::Spec->catfile('model', 'nutcracker', "sv-nutcracker7.rwx"),
		),
	);

	# Add a material sampler
	$self->actor(
		SDL::Tutorial::3DWorld::Actor::MaterialSampler->new(
			hidden   => $self->{hide_expensive},
			position => [ 5, 1, 5 ],
			file     => File::Spec->catfile(
				File::ShareDir::dist_dir('SDL-Tutorial-3DWorld'),
				'example.mtl',
			),
		),
	);

	# Add a sprite
	$self->actor(
		SDL::Tutorial::3DWorld::Actor::Sprite->new(
			scale    => 2,
			position => [ 3, 0, -1 ],
			texture  => $self->sharefile('sprite', 'pguard_die4.png'),
		),
	);

	# Add an eight-sided sprite
	$self->actor(
		SDL::Tutorial::3DWorld::Actor::SpriteOct->new(
			scale    => 2,
			position => [ 5, 0, -1 ],
			texture  => [
				$self->sharefile('sprite', 'mguard_s_1.png'),
				$self->sharefile('sprite', 'mguard_s_2.png'),
				$self->sharefile('sprite', 'mguard_s_3.png'),
				$self->sharefile('sprite', 'mguard_s_4.png'),
				$self->sharefile('sprite', 'mguard_s_5.png'),
				$self->sharefile('sprite', 'mguard_s_6.png'),
				$self->sharefile('sprite', 'mguard_s_7.png'),
				$self->sharefile('sprite', 'mguard_s_8.png'),
			],
		),
	);

	# Add a billboard
	$self->actor(
		SDL::Tutorial::3DWorld::Actor::Billboard->new(
			scale    => 2,
			position => [ 3, 3, 10 ],
			texture  => $self->sharefile('sprite', 'billboard.png'),
		),
	);

	# Add a grid of 100 toilet plungers
	foreach my $x ( -14 .. -5 ) {
		foreach my $z ( 5 .. 14 ) {
			$self->actor(
				SDL::Tutorial::3DWorld::Actor::Model->new(
					position => [ $x, 1.6, $z ],
					file     => File::Spec->catfile(
						'model',
						'toilet-plunger001',
						'toilet_plunger001.obj',
					),
				),
			);
		}
	}

	# Add a grid of 400 texture crates
	foreach my $x ( -24 .. -5 ) {
		foreach my $z ( 5 .. 24 ) {
			$self->actor(
				SDL::Tutorial::3DWorld::Actor::TextureCube->new(
					size     => 1,
					position => [ $x, 0, $z ],
					texture  => $self->sharefile('crate1.jpg'),
				),
			);
		}
	}

	# An recursive icosaheron of toilet plungers in the sky
	$self->actor(
		SDL::Tutorial::3DWorld::Actor::Hedron->icosahedron(
			position => [ -7, 5, 7 ],
			velocity => [ 0, 0, 0  ],
			orient   => [ 0, 0, 1, 0 ],
			rotate   => 1,
			actor    => SDL::Tutorial::3DWorld::Actor::Hedron->icosahedron(
				position => [ 0, 0.95, 0 ],
				actor    => SDL::Tutorial::3DWorld::Actor::Model->new(
					position => [ 0, 0.19, 0 ],
					file     => File::Spec->catfile(
						'model',
						'toilet-plunger001',
						'toilet_plunger001.obj',
					),
				),
			),
		),
	);

	# Add three tron light cycles of varying complexity
	$self->actor(
		SDL::Tutorial::3DWorld::Actor::Model->new(
			position => [ 15, 1, -5 ],
			velocity => [ 0, 0, 0 ],
			orient   => [ 270, 1, 0, 0 ],
			scale    => 0.5,
			file     => File::Spec->catfile(
				'model',
				'gltron',
				'lightcycle-high.obj',
			),
		),
	);

	# Add three tron light cycles of varying complexity
	$self->actor(
		SDL::Tutorial::3DWorld::Actor::Model->new(
			position => [ 10, 1, -5 ],
			velocity => [ 0, 0, 0 ],
			orient   => [ 270, 1, 0, 0 ],
			scale    => 0.5,
			file     => File::Spec->catfile(
				'model',
				'gltron',
				'lightcycle-med.obj',
			),
		),
	);

	# Add three tron light cycles of varying complexity
	$self->actor(
		SDL::Tutorial::3DWorld::Actor::Model->new(
			position => [ 5, 1, -5 ],
			velocity => [ 0, 0, 0 ],
			orient   => [ 270, 1, 0, 0 ],
			scale    => 0.5,
			file     => File::Spec->catfile(
				'model',
				'gltron',
				'lightcycle-low.obj',
			),
		),
	);

	# Add a material sampler for the light cycle
	$self->actor(
		SDL::Tutorial::3DWorld::Actor::MaterialSampler->new(
			hidden   => $self->{hide_expensive},
			position => [ 5, 1, -10 ],
			file     => File::Spec->catfile(
				File::ShareDir::dist_dir('SDL-Tutorial-3DWorld'),
				'model',
				'gltron',
				'lightcycle.mtl',
			),
		),
	);

	return $self;
}

=pod

=head2 camera

The C<camera> method returns the currently active camera for the world.

Provided as a convenience for world objects that need to know where the
camera is (such as the skybox).

=cut

sub camera {
	$_[0]->{camera};
}

=pod

=head2 sdl

The C<sdl> method returns the master L<SDLx::App> object for the world.

=cut

sub sdl {
	$_[0]->{sdl};
}





######################################################################
# Scene Construction

# Add a new actor to the world
sub actor {
	my $self  = shift;
	my $actor = shift;
	my %param = @_;
	push @{$self->{actors}}, $actor;
	push @{$self->{move}},   $actor if     $actor->{velocity};
	push @{$self->{show}},   $actor unless $actor->{hidden};

	# Initialise if needed
	$actor->init if $param{init};

	# Shortcut unless we need the bounding box as well
	return if $self->{benchmark};

	# Add said bounding box
	my $debug = SDL::Tutorial::3DWorld::Actor::Debug->new(
		parent => $actor,
		hidden => $self->{hide_debug},
	);
	push @{$self->{actors}}, $debug;
	push @{$self->{move}},   $debug;
	push @{$self->{show}},   $debug unless $self->{hide_debug};

	# Initialise it too if needed
	$debug->init if $param{init};

	# Returns the actor as a convenience
	return $actor;
}





######################################################################
# Main Methods

=pod

=head2 run

The C<run> method is used to run the game. It takes care of all stages of
the game including initialisation and shutdown operations at the start
and end of the game.

=cut

sub run {
	my $self = shift;

	# Initialise the game
	$self->init;

	# Render handler
	$self->{sdl}->add_show_handler( sub {
		$self->display(@_);
		$self->{sdl}->sync;
	} );

	# Movement handler
	$self->{sdl}->add_move_handler( sub {
		if ( $self->{benchmark} and $_[2] > 100 ) {
			$_[1]->stop;
			return;
		}
		return unless $_[0];
		$self->move(@_);
	} );

	# Event handler
	$self->{sdl}->add_event_handler( sub {
		$self->event(@_);
	} );

	# This world is now the active world
	local $CURRENT = $self;

	# Enter the main loop
	$self->{sdl}->run;

	return 1;
}

=pod

=head2 current

The C<current> method can be used by any arbitrary world element to get
access to the world while it is running.

=cut

sub current {
	$CURRENT or die "No current world is running";
}





######################################################################
# Internal Methods

sub init {
	my $self = shift;

	# Verify the integrity of the installation. This shouldn't really
	# be necesary but kthakore seems to have problems with partial
	# overwriting his installs and mixing up versions of something.
	# This is an attempt to at least partially defend against them.
	foreach my $child ( sort grep { /3DWorld\// } keys %INC ) {
		$child =~ s/\//::/g;
		$child =~ s/\.pm//g;
		next unless Params::Util::_CLASS($child);
		my $v = $child->VERSION;
		unless ( $v ) {
			die "Corrupt installation detected! No \$VERSION in $child";
		}
		unless ( $v == $VERSION ) {
			die "Corrupt installation detected! Got \$VERSION $v in $child but expected $VERSION";
		}
	}

	# Create the SDL application object
	$self->{sdl} = SDLx::App->new(
		title         => '3D World',
		width         => $self->{width},
		height        => $self->{height},
		gl            => 1,
		fullscreen    => $self->{fullscreen},
		depth         => 24, # Prevent harsh colour stepping
		double_buffer => 1,  # Reduce flicker during rapid mouselook
		min_t         => 0,  # As many frames as possible
	);

	# Enable face culling to remove drawing of all rear surfaces
	glCullFace( GL_BACK );
	glEnable( GL_CULL_FACE );

	# Use the prettiest shading available to us
	glShadeModel( GL_SMOOTH );

	# Enable the Z buffer ( DEPTH BUFFER ) so that OpenGL will do all the
	# correct shape culling for us and we don't have to care about it.
	glDepthFunc( GL_LESS );
	glEnable( GL_DEPTH_TEST );

	# How thick are lines
	glLineWidth(1);

	# Enable basic anti-aliasing for everything
	# glEnable( GL_BLEND );
	# glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
	glHint( GL_LINE_SMOOTH_HINT,     GL_NICEST );
	glHint( GL_POINT_SMOOTH_HINT,    GL_NICEST );
	glHint( GL_POLYGON_SMOOTH_HINT,  GL_NICEST );
	glHint( GL_GENERATE_MIPMAP_HINT, GL_NICEST );
	# glEnable( GL_LINE_SMOOTH    );
	# glEnable( GL_POINT_SMOOTH   );
	# glEnable( GL_POLYGON_SMOOTH );

	# Lighting and textures are on by default
	glEnable( GL_LIGHTING );
	glEnable( GL_TEXTURE_2D );

	# Compile a display list to do all non-varying frame reset tasks
	$self->{reset} = OpenGL::List::glpList {
		if ( $self->{skybox} ) {
			# Optimisation:
			# If we have a skybox then no part of the scene will ever show
			# the background. As a result, we can clear only the depth buffer
			# and this will result in the color buffer just being drawn over.
			# This removes a fairly large memory clear operation and speeds
			# up frame-initialisation phase of the rendering pipeline.
			glClear( GL_DEPTH_BUFFER_BIT );
		} else {
			# Clear the colour buffer (what we actually see) and the depth buffer
			# (the area GL uses to remove things behind other things).
			# This gives us a blank screen with our chosen sky colour.
			glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
		}

		# Reset the model, throwing away the previously calculated scene
		# and starting again with a blank sky.
		glMatrixMode( GL_MODELVIEW );
		glLoadIdentity();
	};

	# Initialise the camera so we can look at things
	$self->{camera}->init;

	# Initialise and load the skybox
	if ( $self->{skybox} ) {
		$self->{skybox}->init;
	}

	# Initialise the landscape so there is a world
	$self->{landscape}->init;

	# Initialise the actors.
	# Randomise the order once to generate interesting effects.
	foreach my $actor ( @{$self->{actors}} ) {
		$actor->init;
	}

	# Initialise the console
	if ( $self->{console} ) {
		$self->{console}->init;
	}

	# Initialise and enable the fog (in this case a light ground haze)
	if ( $self->{fog} ) {
		$self->{fog}->init;
		$self->{fog}->enable;
	}

	return 1;
}

sub event {
	my $self = shift;

	# Handle any events related to the camera.
	# Since the move common high frequency events will be stuff like
	# mouse movements to control mouselook we do this first.
	$self->{camera}->event(@_) and return 1;

	# Now handle lower-frequency events related to the application
	# as a whole or elements within it.
	my $event = shift;
	my $type  = $event->type;
	if ( $type == SDL_KEYDOWN ) {
		my $key = $event->key_sym;

		# Quit the world
		if ( $key == SDLK_ESCAPE ) {
			$self->{sdl}->stop;
			return 1;
		}

		# Toggle visibility of debugging actors
		if ( $key == SDLK_F1 ) {
			$self->{hide_debug} = $self->{hide_debug} ? 0 : 1;
			foreach my $actor ( @{$self->{actors}} ) {
				next unless $actor->isa('SDL::Tutorial::3DWorld::Actor::Debug');
				$actor->{hidden} = $self->{hide_debug};
			}

			# Rebuild the index of visible objects
			@{$self->{show}} = grep { not $_->{hidden} } @{$self->{actors}};

			return 1;
		}

		# Toggle visibility for unrealistically-expensive actors
		if ( $key == SDLK_F2 ) {
			$self->{hide_expensive} = $self->{hide_expensive} ? 0 : 1;
			foreach my $actor ( @{$self->{actors}} ) {
				if ( $actor->isa('SDL::Tutorial::3DWorld::Actor::MaterialSampler') ) {
					$actor->{hidden} = $self->{hide_expensive};
				}
				if ( $actor->isa('SDL::Tutorial::3DWorld::Actor::Teapot') ) {
					$actor->{hidden} = $self->{hide_expensive};
				}
			}

			# Rebuild the index of visible objects
			@{$self->{show}} = grep { not $_->{hidden} } @{$self->{actors}};

			return 1;
		}

		# Toggle visibility of the console (i.e. the FPS display)
		if ( $key == SDLK_F3 ) {
			$self->{hide_console} = $self->{hide_console} ? 0 : 1;
			return 1;
		}

		# Trigger bit's "Yes" or "No" cycle
		if ( $key == SDLK_y ) {
			$self->{bit}->yes;
			return 1;
		}
		if ( $key == SDLK_n ) {
			$self->{bit}->no;
			return 1;
		}

	} elsif ( $type == SDL_MOUSEBUTTONDOWN ) {
		# Make the scroll wheel move the selection box towards
		# and away from the camera.
		my $selector = $self->{selector};
		my $button  = $event->button_button;
		if ( $button == SDL_BUTTON_WHEELUP ) {
			# Move away from the camera
			$selector->{distance} += 0.5;
			return 1;
		}
		if ( $button == SDL_BUTTON_WHEELDOWN ) {
			# Move towards the camera, stopping
			# at some suitable minimum distance.
			$selector->{distance} -= 0.5;
			if ( $selector->{distance} < 2 ) {
				$selector->{distance} = 2;
			}
			return 1;
		}

		# Place a new texture box at the selector location
		if ( $button == SDL_BUTTON_LEFT ) {
			my $cube = SDL::Tutorial::3DWorld::Actor::TextureCube->new(
				position => [
					$selector->{position}->[0] + 0.5,
					$selector->{position}->[1],
					$selector->{position}->[2] + 0.5,
				],
				material => {
					ambient => [ 0.5, 0.5, 0.5, 1 ],
					texture => $self->sharefile('crate1.jpg'),
				},
			);
			$self->actor( $cube, init => 1 );
			return 1;
		}

		# Let right mouse button drop us back into debugging
		if ( $button == SDL_BUTTON_RIGHT ) {
			$DB::single = 1;
		}
	}

	return 1;
}

sub move {
	my $self = shift;
	my $move = $self->{move};

	# Move each of the actors in the scene.
	$_->move(@_) foreach @$move;

	# Move the camera last, since it is more likely that the position
	# of the camera will be limited by where the actors are than the
	# actors being limited by where the camera is. Especially since the
	# camera doesn't currently have an avatar.
	$self->{camera}->move(@_);
}

# This is the primary render loop
sub display {
	my $self   = shift;
	my $camera = $self->{camera};

	# Reset the frame
	glCallList( $self->{reset} );

	# Move the camera to the required position.
	# NOTE: For now just translate back so we can see the render.
	$camera->display;

	# Draw the skybox
	$self->{skybox}->display if $self->{skybox};

	# Draw the landscape in the scene
	$self->{landscape}->display;

	# Light the scene.
	#  All lighting is global in this demonstration.
	foreach my $light ( @{$self->{lights}} ) {
		$light->display;
	}

	# Display all of the actors visible by the main scene camera.
	# Pass the camera because later we may want to do some tricks involving
	# multiple cameras.
	$self->display_actors($camera);

	# Draw the console last, on top of everything else
	if ( $self->{console} and not $self->{hide_console} ) {
		$self->{console}->display;
	}

	return 1;
}

# Simultaneously cull and render the solid objects in the scene,
# storing blending objects for a second sorting/render pass.
sub display_actors {
	my $self     = shift;
	my $camera   = shift;
	my $show     = $self->{show};
	my @blend    = ();
	my @distance = ();
	foreach my $actor ( @$show ) {
		my $position = $actor->{position};
		my $bound    = $actor->{bound};

		# Most things should have bounding boxes
		if ( $actor->{bound} ) {
			# Sphere-sphere culling, which is really fast.
			# Compare sizes of the squares to avoid extra sqrt calls.
			(
				($bound->[SPHERE_R] + $camera->{rsphere}) ** 2 # $RS
			) > (
				($position->[0] + $bound->[SPHERE_X] - $camera->{xsphere}) ** 2 + # $XS
				($position->[1] + $bound->[SPHERE_Y] - $camera->{ysphere}) ** 2 + # $YS
				($position->[2] + $bound->[SPHERE_Z] - $camera->{zsphere}) ** 2   # $ZS
			) or next;

			# Second pass is cone-sphere culling, which is slower but
			# will cull down to something reasonsably close to the ideal.
			### NOTE: TO BE IMPLEMENTED LATER

		} else {

			# Sphere-point culling for actors without volume (and
			# thus no bounding shapes). This is similar to
			# sphere-sphere but slightly simpler as it effectively
			# uses a zero-offset zero-size bounding sphere.
			(
				$camera->{rsphere} ** 2
			) > (
				($position->[0] - $camera->{xsphere}) ** 2 + # $XS
				($position->[1] - $camera->{ysphere}) ** 2 + # $YS
				($position->[2] - $camera->{zsphere}) ** 2   # $ZS
			) or next;
		}

		# Objects that need blending must be rendered from furthest
		# to nearest, but the render order of solid objects is mostly
		# irrelevant. So we render solid stuff immediately.
		unless ( $actor->{blending} ) {
			defined( $actor->{display} )
				# If the actor has a completely pre-built display list,
				# shortcut their display method and just draw it.
				# The actor is expected to do everything, including the
				# push/pop matrix operation shown below to isolate drawing.
				? glCallList( $actor->{display} )
				: do {
					# Draw each actor in their own stack context so that
					# their transform operations do not effect anything else.
					glPushMatrix();
					$actor->display;
					glPopMatrix();
				};
			next;
		}

		# Precalculate the distance now. Because we are only
		# using it for sorting we can safely avoid the sqrt
		# and sort on the squared distance instead.
		push @blend, $actor;
		push @distance, (
			($camera->{X} - $position->[0]) ** 2 +
			($camera->{Y} - $position->[1]) ** 2 +
			($camera->{Z} - $position->[2]) ** 2
		);
	}

	# Render the remaining elements in sorted order
	foreach my $actor (
		map {
			$blend[$_]
		} sort {
			$distance[$b] <=> $distance[$a]
		} ( 0 .. $#blend )
	) {
		# Repeat the display code shown above
		defined( $actor->{display} )
			? glCallList( $actor->{display} )
			: do {
				glPushMatrix();
				$actor->display;
				glPopMatrix();
			};
	}

	# Disable normalisation in case the last object left us
	# with normalisation enabled.
	OpenGL::glDisable( OpenGL::GL_NORMALIZE );

	return 1;
}





######################################################################
# Utility Methods

sub dvector {
	my $dt = $_[0]->{dt};
	return [
		$_[1] * $dt,
		$_[2] * $dt,
		$_[3] * $dt,
	];
}

sub dscalar {
	$_[0]->{dt} * $_[1];
}

sub sharedir {
	my $self = shift;
	File::Spec->rel2abs(
		File::Spec->catdir(
			File::ShareDir::dist_dir('SDL-Tutorial-3DWorld'),
			@_,
		),
	);
}

sub sharefile {
	my $self = shift;
	File::Spec->rel2abs(
		File::Spec->catfile(
			File::ShareDir::dist_dir('SDL-Tutorial-3DWorld'),
			@_,
		),
	);
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

Copyright 2010 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
