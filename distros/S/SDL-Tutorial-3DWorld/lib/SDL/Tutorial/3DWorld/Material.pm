package SDL::Tutorial::3DWorld::Material;

use 5.008;
use strict;
use warnings;
use SDL::Tutorial::3DWorld::OpenGL ();

our $VERSION = '0.33';

# Convert GL fake "constants" to real constants.
# If we don't do this we spend a third of our CPU calling constants.
use constant {
	GL_AMBIENT             => OpenGL::GL_AMBIENT,
	GL_BLEND               => OpenGL::GL_BLEND,
	GL_DIFFUSE             => OpenGL::GL_DIFFUSE,
	GL_FRONT               => OpenGL::GL_FRONT,
	GL_LIGHTING            => OpenGL::GL_LIGHTING,
	GL_ONE_MINUS_SRC_ALPHA => OpenGL::GL_ONE_MINUS_SRC_ALPHA,
	GL_SHININESS           => OpenGL::GL_SHININESS,
	GL_SRC_ALPHA           => OpenGL::GL_SRC_ALPHA,
	GL_SPECULAR            => OpenGL::GL_SPECULAR,
	GL_TEXTURE_2D          => OpenGL::GL_TEXTURE_2D,
};





######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless {
		# Default elements
		color        => [ 1.0, 1.0, 1.0      ],
		ambient      => [ 0.2, 0.2, 0.2, 1.0 ],
		diffuse      => [ 0.8, 0.8, 0.8, 1.0 ],
		specular     => 0,
		dissolve     => 1.0,
		shininess    => 127,
		texture      => undef,
		illumination => 2,
		@_,
	}, $class;

	# If our colours are only 3 element, apply the dissolve
	if ( @{$self->{ambient}} == 3 ) {
		$self->{ambient}->[3] = $self->{dissolve};
	}
	if ( @{$self->{diffuse}} == 3 ) {
		$self->{diffuse}->[3] = $self->{dissolve};
	}
	if ( $self->{specular} and @{$self->{specular}} == 3 ) {
		$self->{specular}->[3] = $self->{dissolve};
	}

	# Inflate texture filenames to texture objects
	if ( $self->{texture} and not ref $self->{texture} ) {
		$self->{texture} = SDL::Tutorial::3DWorld::Texture->new(
			file => $self->{texture},
		);
	}

	# Enable the blending flag if needed
	if ( $self->{ambient}->[3] < 1 ) {
		$self->{blending} = 1;
	} elsif ( $self->{diffuse}->[3] < 1 ) {
		$self->{blending} = 1;
	}

	return $self;
}

sub clone {
	my $self = shift;

	# Basic shallow clone
	my $class = ref $self;
	my $clone = bless { %$self }, $class;

	# Deep clone multi-element colours
	$clone->{ambient}  = [ @{$clone->{ambient}}  ];
	$clone->{diffuse}  = [ @{$clone->{diffuse}}  ];
	$clone->{specular} = [ @{$clone->{specular}} ] if $clone->{specular};

	return $clone;
}

sub color {
	$_[0]->{color};
}

sub ambient {
	$_[0]->{ambient};
}

sub diffuse {
	$_[0]->{diffuse};
}

sub specular {
	$_[0]->{specular};
}

sub shininess {
	$_[0]->{shininess};
}

sub texture {
	$_[0]->{texture};
}

# Illumination mode
# 0. Color on and Ambient off
# 1. Color on and Ambient on
# 2. Highlight on
# 3. Reflection on and Ray trace on
# 4. Transparency: Glass on, Reflection: Ray trace on
# 5. Reflection: Fresnel on and Ray trace on
# 6. Transparency: Refraction on, Reflection: Fresnel off and Ray trace on
# 7. Transparency: Refraction on, Reflection: Fresnel on and Ray trace on
# 8. Reflection on and Ray trace off
# 9. Transparency: Glass on, Reflection: Ray trace off
# 10. Casts shadows onto invisible surfaces
sub illumination {
	$_[0]->{illumination};
}





######################################################################
# Mutators

sub set_color {
	my $self = shift;
	$self->{color} = shift;
}

sub set_texture {
	my $self = shift;
	$self->{texture} = shift;
}

sub set_ambient {
	my $self    = shift;
	my @ambient = @_;

	# One-value ambient is defined as a multiple of the current colour
	if ( @ambient == 1 and ref $ambient[0] ) {
		@ambient = @{$ambient[0]};
	}
	if ( @ambient == 1 ) {
		@ambient = (
			$self->{color}->[0] * $ambient[0],
			$self->{color}->[1] * $ambient[0],
			$self->{color}->[2] * $ambient[0],
		);
	}

	# Three-value ambient is a material property without an alpha value
	if ( @ambient == 3 ) {
		push @ambient, $self->{ambient}->[3];
	}

	# Four-value ambient is a full material property and replaces the
	# current value directly.
	if ( @ambient == 4 ) {
		$self->{ambient} = \@ambient;
		return 1;
	}

	die "Unknown or unsupported ambient color definition";
}

sub set_diffuse {
	my $self    = shift;
	my @diffuse = @_;

	# One-value diffuse is defined as a multiple of the current colour
	if ( @diffuse == 1 and ref $diffuse[0] ) {
		@diffuse = @{$diffuse[0]};
	}
	if ( @diffuse == 1 ) {
		@diffuse = (
			$self->{color}->[0] * $diffuse[0],
			$self->{color}->[1] * $diffuse[0],
			$self->{color}->[2] * $diffuse[0],
		);
	}

	# Three-value diffuse is a material property without an alpha value
	if ( @diffuse == 3 ) {
		push @diffuse, $self->{diffuse}->[3];
	}

	# Four-value diffuse is a full material property and replaces the
	# current value directly.
	if ( @diffuse == 4 ) {
		$self->{diffuse} = \@diffuse;
		return 1;
	}

	die "Unknown or unsupported diffuse color definition";
}

sub set_opacity {
	my $self    = shift;
	my $opacity = shift;

	# Opacity effects the ambient and diffuse values only
	$self->{ambient}->[3] = 1 - $opacity;
	$self->{diffuse}->[3] = 1 - $opacity;

	# Turn on the blending flag if needed
	if ( $opacity < 1 ) {
		$self->{blending} = 1;
	}

	return 1;
}





######################################################################
# Engine Methods

sub init {
	my $self = shift;
	if ( $self->{texture} ) {
		$self->{texture}->init;
	}
	return 1;
}

# Apply the material to the current OpenGL context
sub display {
	my $self = shift;

	# Enable or disable blending if the material is not entirely solid
	if ( $self->{blending} ) {
		OpenGL::glEnable( GL_BLEND );
		OpenGL::glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
	} else {
		OpenGL::glDisable( GL_BLEND );
	}

	# Apply the material properties
	OpenGL::glEnable( GL_LIGHTING );
	if ( $self->{texture} ) {
		OpenGL::glEnable( GL_TEXTURE_2D );
		OpenGL::glColor3f( @{$self->{color}} );
		$self->{texture}->display;
	} else {
		OpenGL::glDisable( GL_TEXTURE_2D );
		OpenGL::glColor3f( 0, 0, 0 );
	}
	OpenGL::glMaterialfv_p(
		GL_FRONT,
		GL_AMBIENT,
		@{ $self->{ambient} },
	);
	OpenGL::glMaterialfv_p(
		GL_FRONT,
		GL_DIFFUSE,
		@{ $self->{diffuse} },
	);
	if ( $self->{specular} ) {
		OpenGL::glMaterialfv_p(
			GL_FRONT,
			GL_SPECULAR,
			@{ $self->{specular} },
		);
		OpenGL::glMaterialf(
			GL_FRONT,
			GL_SHININESS,
			$self->{shininess},
		);
	} else {
		OpenGL::glMaterialfv_p(
			GL_FRONT,
			GL_SPECULAR,
			0, 0, 0, 1,
		);
		OpenGL::glMaterialf(
			GL_FRONT,
			GL_SHININESS,
			100.23,
		);
	}

	return 1;
}

1;
