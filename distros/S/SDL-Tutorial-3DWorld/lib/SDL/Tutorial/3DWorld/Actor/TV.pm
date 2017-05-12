package SDL::Tutorial::3DWorld::Actor::TV;

# Attempt to implement a "Television Screen" that can
# play MPEG streams, suitable for incorporation into more
# complex video-device models.

use 5.008;
use strict;
use warnings;
use SDL;
use SDL::SMPEG;
use SDL::Surface;
use SDL::Tutorial::3DWorld::OpenGL ();
use SDL::Tutorial::3DWorld::Actor  ();

our $VERSION = '0.33';
our @ISA     = 'SDL::Tutorial::3DWorld::Actor';





######################################################################
# Constructor

sub new {
	my $self = shift->SUPER::new(@_);

	# Do we have a video file?
	unless ( $self->{file} ) {
		die "Did not provide a video file";
	}

	return $self;
}





######################################################################
# Engine Methods

sub init {
	my $self = shift;

	# Create the SDL surface for the video. We'll be keeping this
	# permanently so we can shuttle video frames through it.
	$self->{surface} = SDL::Surface->new(
		$self->{height}, $self->{width}, 24,
		0, 0, 0, 0
	);

	# Load the video stream
	$self->{smpeg} = SDL::SMPEG->new(
		-name  => $self->{file},
		-audio => 0,
	) or die "Failed to load MPEG stream from '$self->{file}'";

	# Capture some useful metadata about the stream
	my $info = $self->{smpeg}->info or die "SMPEG->info failed";
	$self->{height} = $info->height;
	$self->{width}  = $info->width;

	# Scale the TV size to the aspect ratio of the video
	$self->{aspect} = $self->{width} / $self->{height};
	$self->{scale}  = [ $self->{aspect}, 1, 1 ];

	# Bind the video to the surface
	$self->{smpeg}->display( $self->{surface} );

	# Render the first frame of the video to the screen
	$self->{smpeg}->frame(1); # Should this be zero?

	# Generate the GL texture values
	my $format = $self->{surface}->format;
	$self->{bytes} = $format->BytesPerPixel;
	if ( $self->{bytes} == 4 ) {
		# Contains an alpha channel
		if ( $format->Rmask == 0x000000ff ) {
			$self->{mask} = OpenGL::GL_RGBA;
		} else {
			$self->{mask} = OpenGL::GL_BGRA;
		}
	} elsif ( $self->{bytes} == 3 ) {
		# Does not contain an alpha channel
		if ( $format->Rmask == 0x000000ff ) {
			$self->{mask} = OpenGL::GL_RGB;
		} else {
			$self->{mask} = OpenGL::GL_BGR;
		}
	} else {
		die "Unknown or unsupported video '$self->{file}'";
	}

	# Have OpenGL generate one texture object handle.
	$self->{id} = OpenGL::glGenTextures_p(1);

	# Bind the texture object for the first time, activating it
	# as the "current" texture and confirming it as 2 dimensional.
	OpenGL::glBindTexture( OpenGL::GL_TEXTURE_2D, $self->{id} );

	# Specify how the texture will display when we are far from the
	# texture and many texture pixels are inside one display pixel.
	OpenGL::glTexParameterf(
		OpenGL::GL_TEXTURE_2D,
		OpenGL::GL_TEXTURE_MIN_FILTER,
		OpenGL::GL_NEAREST,
	);

	# Specify the zoom method to use when we are too close to the
	# texture and one texture pixel spreads over many display pixels.
	OpenGL::glTexParameterf(
		OpenGL::GL_TEXTURE_2D,
		OpenGL::GL_TEXTURE_MAG_FILTER,
		OpenGL::GL_NEAREST,
	);

	# Lock the surface so the frame holds still in memory
	SDL::Video::lock_surface($self->{surface});

	# Write the image data into the texture,
	# generating mipmaps as we go (is this too expensive?)
	OpenGL::gluBuild2DMipmaps_s(
		OpenGL::GL_TEXTURE_2D,
		$self->{bytes},
		$self->{width},
		$self->{height},
		$self->{mask},
		OpenGL::GL_UNSIGNED_BYTE,
		${ $self->{surface}->get_pixels_ptr },
	);

	# Release the lock on the SDL surface
	SDL::Video::unlock_surface($self->{surface});

	return 1;
}

sub display {
	my $self = shift;
	$self->SUPER::display(@_);

	# Display the frame
	OpenGL::glDisable( OpenGL::GL_LIGHTING );
	OpenGL::glColorf( 1, 1, 1, 1 );
	OpenGL::glBindTexture( OpenGL::GL_TEXTURE_2D, $self->{id} );
	OpenGL::glBegin( OpenGL::GL_QUADS );
	OpenGL::glTexCoord2f( 0, 0 ); OpenGL::glVertex3f( -0.5,  1,  0 ); # Top Left
	OpenGL::glTexCoord2f( 0, 1 ); OpenGL::glVertex3f( -0.5,  0,  0 ); # Bottom Left
	OpenGL::glTexCoord2f( 1, 1 ); OpenGL::glVertex3f(  0.5,  0,  0 ); # Bottom Right
	OpenGL::glTexCoord2f( 1, 0 ); OpenGL::glVertex3f(  0.5,  1,  0 ); # Top Right
	OpenGL::glEnd();
	OpenGL::glEnable( OpenGL::GL_LIGHTING );

	return 1;
}

1;
