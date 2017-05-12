package SDL::Tutorial::3DWorld::Mesh;

use 5.008;
use strict;
use warnings;
use OpenGL                           ();
use OpenGL::List                     ();
use List::MoreUtils                  ();
use SDL::Tutorial::3DWorld::OpenGL   ();
use SDL::Tutorial::3DWorld::Material ();

our $VERSION = '0.33';

# Detect support for Vertex Buffer 



######################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless {
		material => [
			# We put in a default base material both so
			# that mesh without any materials won't end
			# up being rendered manually, and so that file
			# formats that describe material changes in delta
			# form have a base to change from.
			SDL::Tutorial::3DWorld::Material->new,
		],
		vertex   => [ undef ],
		normal   => [ undef ],
		uv       => [ undef ],
		face     => [ ],
		box      => [ ],
	}, $class;
	return $self;
}

sub box {
	@{$_[0]->{box}};
}

sub max_vertex {
	my $self   = shift;
	my $vertex = $self->{vertex};
	return $#$vertex;
}





######################################################################
# Material Definition

# Add a new material either as full material object or a set of
# parameters that act as a delta to the previous material.
# Return the material id of the new material.
sub add_material {
	my $self    = shift;
	my $array   = $self->{material};
	my $current = $array->[-1];

	# Save the material directly if passed an object
	if ( Params::Util::_INSTANCE($_[0], 'SDL::Tutorial::3DWorld::Material') ) {
		my $material = shift;
		push @$array, $material;
		return $#$array;
	}

	# Apply the provided changes
	my %options  = @_;
	my $material = $current->clone;
	if ( exists $options{color} ) {
		$material->set_color( delete $options{color} );
	}
	if ( exists $options{texture} ) {
		$material->set_texture( delete $options{texture} );
	}
	if ( exists $options{ambient} ) {
		$material->set_ambient( delete $options{ambient} );
	}
	if ( exists $options{diffuse} ) {
		$material->set_diffuse( delete $options{diffuse} );
	}
	if ( exists $options{opacity} ) {
		$material->set_opacity( delete $options{opacity} );
	}
	if ( %options ) {
		die "One or more unsupported material options";	
	}

	push @$array, $material;
	return $#$array;
}





######################################################################
# Geometry Assembly

sub add_all {
	my $self = shift;
	my $i    = scalar @{ $self->{vertex} };
	my @v    = @{$_[0]};
	$self->{vertex}->[$i] = \@v;
	$self->{uv}->[$i]     = $_[1];
	$self->{normal}->[$i] = $_[2];

	# Update the bounding box
	my $box  = $self->{box};
	unless ( @$box ) {
		@$box = ( @v, @v );
		return;
	}
	if ( $v[0] < $box->[0] ) {
		$box->[0] = $v[0];
	} elsif ( $v[0] > $box->[3] ) {
		$box->[3] = $v[0];
	}
	if ( $v[1] < $box->[1] ) {
		$box->[1] = $v[1];
	} elsif ( $v[1] > $box->[4] ) {
		$box->[4] = $v[1];
	}
	if ( $v[2] < $box->[2] ) {
		$box->[2] = $v[2];
	} elsif ( $v[2] > $box->[5] ) {
		$box->[5] = $v[2];
	}
	return;
}

sub add_vertex {
	my $self = shift;
	push @{ $self->{vertex} }, [ @_ ];

	# Update the bounding box
	my $box  = $self->{box};
	unless ( @$box ) {
		@$box = ( @_, @_ );
		return;
	}
	if ( $_[0] < $box->[0] ) {
		$box->[0] = $_[0];
	} elsif ( $_[0] > $box->[3] ) {
		$box->[3] = $_[0];
	}
	if ( $_[1] < $box->[1] ) {
		$box->[1] = $_[1];
	} elsif ( $_[1] > $box->[4] ) {
		$box->[4] = $_[1];
	}
	if ( $_[2] < $box->[2] ) {
		$box->[2] = $_[2];
	} elsif ( $_[2] > $box->[5] ) {
		$box->[5] = $_[2];
	}
	return;
}

# Add an explicit normal
# The fourth element indicates the normal is explicit, final, and should be
# excluded from automatic normal calculations.
sub add_normal {
	push @{ shift->{normal} }, [ @_, 1 ];
}

sub add_uv {
	push @{ shift->{uv} }, [ @_ ];
}

sub add_triangle {
	my $self     = shift;
	my $material = $self->{material};
	my $vertex   = $self->{vertex};
	my $normal   = $self->{normal};

	# We get an index set of up to ten things
	# - One material index
	# - Three vertex index
	# - Three optional normal index
	# - Three optional uv index
	my $M  = $material->[$_[0]] or die "No material $_[0]";
	my $V0 = $vertex->[$_[1]]   or die "No vertex $_[1]";
	my $V1 = $vertex->[$_[2]]   or die "No vertex $_[2]";
	my $V2 = $vertex->[$_[3]]   or die "No vertex $_[3]";
	my $N0 = $normal->[$_[7] || 0];
	my $N1 = $normal->[$_[8] || 0];
	my $N2 = $normal->[$_[9] || 0];

	# Where a face has no normal defined, use one for the vertex if it
	# exists, or auto-instantiate a normal to match the vertex if one
	# does not exist already.
	$N0 = $normal->[$_[1]] unless $N0;
	$N1 = $normal->[$_[2]] unless $N1;
	$N2 = $normal->[$_[3]] unless $N2;
	$N0 = $normal->[$_[1]] = [ 0, 0, 0 ] unless $N0;
	$N1 = $normal->[$_[2]] = [ 0, 0, 0 ] unless $N1;
	$N2 = $normal->[$_[3]] = [ 0, 0, 0 ] unless $N2;

	# Looks good enough, save the face
	push @{ $self->{face} }, [ 3, @_ ];

	# Shortcut if all the normals are final and we don't need to do
	# automatic normal calculations.
	if ( $N0->[3] and $N1->[3] and $N2->[3] ) {
		return 1;
	}

	# Find vectors for two sides
	my $xa = $V0->[0] - $V1->[0];
	my $ya = $V0->[1] - $V1->[1];
	my $za = $V0->[2] - $V1->[2];
	my $xb = $V1->[0] - $V2->[0];
	my $yb = $V1->[1] - $V2->[1];
	my $zb = $V1->[2] - $V2->[2];

	# Calculate the cross product vector
	my $xn = ($ya * $zb) - ($za * $yb);
	my $yn = ($za * $xb) - ($xa * $zb);
	my $zn = ($xa * $yb) - ($ya * $xb);

	# Add the non-sqrt'ed cross product to each non-final vector so
	# that vertex normals are averaged in proportion to face sizes.
	# This is a recommendation seen on a demo scene tutorial.
	unless ( $N0->[3] ) {
		$N0->[0] += $xn;
		$N0->[1] += $yn;
		$N0->[2] += $zn;
	}
	unless ( $N1->[3] ) {
		$N1->[0] += $xn;
		$N1->[1] += $yn;
		$N1->[2] += $zn;
	}
	unless ( $N2->[3] ) {
		$N2->[0] += $xn;
		$N2->[1] += $yn;
		$N2->[2] += $zn;
	}
	return;
}

sub add_quad {
	my $self     = shift;
	my $material = $self->{material};
	my $vertex   = $self->{vertex};
	my $normal   = $self->{normal};

	# We get an index set of up to thirteen things
	# - One material index
	# - Four vertex index
	# - Four optional normal index
	# - Four optional uv index
	my $M  = $material->[$_[0]] or die "No material $_[0]";
	my $V0 = $vertex->[$_[1]]   or die "No vertex $_[1]";
	my $V1 = $vertex->[$_[2]]   or die "No vertex $_[2]";
	my $V2 = $vertex->[$_[3]]   or die "No vertex $_[3]";
	my $V3 = $vertex->[$_[4]]   or die "No vertex $_[4]";
	my $N0 = $normal->[$_[9]  || 0];
	my $N1 = $normal->[$_[10] || 0];
	my $N2 = $normal->[$_[11] || 0];
	my $N3 = $normal->[$_[12] || 0];

	# Where a face has no normal defined, use one for the vertex if it
	# exists, or auto-instantiate a normal to match the vertex if one
	# does not exist already.
	$N0 = $normal->[$_[1]] unless $N0;
	$N1 = $normal->[$_[2]] unless $N1;
	$N2 = $normal->[$_[3]] unless $N2;
	$N3 = $normal->[$_[4]] unless $N3;
	$N0 = $normal->[$_[1]] = [ 0, 0, 0 ] unless $N0;
	$N1 = $normal->[$_[2]] = [ 0, 0, 0 ] unless $N1;
	$N2 = $normal->[$_[3]] = [ 0, 0, 0 ] unless $N2;
	$N3 = $normal->[$_[4]] = [ 0, 0, 0 ] unless $N3;

	# Looks good enough, save the face
	push @{ $self->{face} }, [ 4, @_ ];

	# Shortcut if all the normals are final and we don't need to do
	# automatic normal calculations.
	if ( $N0->[3] and $N1->[3] and $N2->[3] and $N3->[3] ) {
		return 1;
	}

	# Find vectors for two sides
	my $xa = $V0->[0] - $V1->[0];
	my $ya = $V0->[1] - $V1->[1];
	my $za = $V0->[2] - $V1->[2];
	my $xb = $V1->[0] - $V2->[0];
	my $yb = $V1->[1] - $V2->[1];
	my $zb = $V1->[2] - $V2->[2];

	# Calculate the cross product vector
	my $xn = ($ya * $zb) - ($za * $yb);
	my $yn = ($za * $xb) - ($xa * $zb);
	my $zn = ($xa * $yb) - ($ya * $xb);

	# Add the non-sqrt'ed cross product to each non-final vector so
	# that vertex normals are averaged in proportion to face sizes.
	# This is a recommendation seen on a demo scene tutorial.
	unless ( $N0->[3] ) {
		$N0->[0] += $xn;
		$N0->[1] += $yn;
		$N0->[2] += $zn;
	}
	unless ( $N1->[3] ) {
		$N1->[0] += $xn;
		$N1->[1] += $yn;
		$N1->[2] += $zn;
	}
	unless ( $N2->[3] ) {
		$N2->[0] += $xn;
		$N2->[1] += $yn;
		$N2->[2] += $zn;
	}
	unless ( $N3->[3] ) {
		$N3->[0] += $xn;
		$N3->[1] += $yn;
		$N3->[2] += $zn;
	}

	return;
}





######################################################################
# Engine Methods

# Even through OpenGL can do surface vector normalisation itself, it is
# still better that we do it slower and once here than faster and many
# times in hardware.
sub init {
	my $self = shift;

	# Normalise the surface vectors (reduce to 1 unit length)
	foreach my $n ( @{$self->{normal}} ) {
		# In some situations (for example if there are vectors not
		# used by faces and we are doing implicit surface normals)
		# the normal array might have null entries.
		next unless $n;

		# Assume that any explicit surface vectors are normalised
		if ( $n->[3] ) {
			delete $n->[3];
			next;
		}

		# Do the normalisation
		my $l = sqrt( ($n->[0] ** 2) + ($n->[1] ** 2) + ($n->[2] ** 2) ) || 1;
		$n->[0] /= $l;
		$n->[1] /= $l;
		$n->[2] /= $l;
	}

	# Initialise the subset of materials actually used by the faces
	my %seen = ();
	foreach my $face ( @{$self->{face}} ) {
		next unless not $seen{$face->[1]}++;
		$self->{material}->[$face->[1]]->init;
	}

	return $self->{init} = 1;
}

sub display {
	my $self = shift;

	# Auto-initialise
	$self->{init} or $self->init;

	# Set up and apply defaults
	my $material = $self->{material};
	my $vertex   = $self->{vertex};
	my $normal   = $self->{normal};
	my $uv       = $self->{uv};
	my $face     = $self->{face};
	my $begin    = 0;

	# Initialise the material to the material of the first face.
	# We do this in full here so that initial material setup (which
	# is being done from an untrusted material state) is not impacted
	# by any future material delta optimisations below in future.
	my $current = $face->[0]->[1];
	$material->[$current]->display;

	# Render the faces
	foreach my $f ( @$face ) {
		my $t = $f->[0];
		my $m = $f->[1];

		# End previous drawing sequence if needed
		unless ( $t == $begin and $m == $current ) {
			OpenGL::glEnd() if $begin;
			$begin = 0;
		}

		# Switch materials
		unless ( $m == $current ) {
			$material->[$m]->display;
			$current = $m;
		}

		if ( $t == 4 ) {
			# Quad
			my $v0 = $vertex->[$f->[2]];
			my $v1 = $vertex->[$f->[3]];
			my $v2 = $vertex->[$f->[4]];
			my $v3 = $vertex->[$f->[5]];
			my $t0 = $uv->[$f->[6] || 0];
			my $t1 = $uv->[$f->[7] || 0];
			my $t2 = $uv->[$f->[8] || 0];
			my $t3 = $uv->[$f->[9] || 0];
			my $n0 = $normal->[$f->[10] || $f->[2]];
			my $n1 = $normal->[$f->[11] || $f->[3]];
			my $n2 = $normal->[$f->[12] || $f->[4]];
			my $n3 = $normal->[$f->[13] || $f->[5]];

			# Start the new geometry sequence
			unless ( $begin ) {
				OpenGL::glBegin( OpenGL::GL_QUADS );
				$begin = $t;
			}

			# Draw the quad
			OpenGL::glTexCoord2f( @$t0 ) if $t0;
			OpenGL::glNormal3f( @$n0 );
			OpenGL::glVertex3f( @$v0 );
			OpenGL::glTexCoord2f( @$t1 ) if $t1;
			OpenGL::glNormal3f( @$n1 );
			OpenGL::glVertex3f( @$v1 );
			OpenGL::glTexCoord2f( @$t2 ) if $t2;
			OpenGL::glNormal3f( @$n2 );
			OpenGL::glVertex3f( @$v2 );
			OpenGL::glTexCoord2f( @$t3 ) if $t3;
			OpenGL::glNormal3f( @$n3 );
			OpenGL::glVertex3f( @$v3 );

		# We only support triangles and quads
		} else {
			# Triangle
			my $v0 = $vertex->[$f->[2]];
			my $v1 = $vertex->[$f->[3]];
			my $v2 = $vertex->[$f->[4]];
			my $t0 = $uv->[$f->[5] || 0];
			my $t1 = $uv->[$f->[6] || 0];
			my $t2 = $uv->[$f->[7] || 0];
			my $n0 = $normal->[$f->[8] || $f->[2]];
			my $n1 = $normal->[$f->[9] || $f->[3]];
			my $n2 = $normal->[$f->[10] || $f->[4]];

			# Start the new geometry sequence
			unless ( $begin ) {
				OpenGL::glBegin( OpenGL::GL_TRIANGLES );
				$begin = 3;
			}

			# Draw the triangle
			OpenGL::glTexCoord2f( @$t0 ) if $t0;
			OpenGL::glNormal3f( @$n0 );
			OpenGL::glVertex3f( @$v0 );
			OpenGL::glTexCoord2f( @$t1 ) if $t1;
			OpenGL::glNormal3f( @$n1 );
			OpenGL::glVertex3f( @$v1 );
			OpenGL::glTexCoord2f( @$t2 ) if $t2;
			OpenGL::glNormal3f( @$n2 );
			OpenGL::glVertex3f( @$v2 );

		}
	}

	# Clean up the final drawing mode
	OpenGL::glEnd() if $begin;

	return 1;
}

# Generate a display list for the mesh
sub as_list {
	my $self = shift;
	return OpenGL::List::glpList {
		$self->display;
	};
}





######################################################################
# Vertex Buffer Array Renderer

sub as_oga {
	my $self   = shift;
	my $vertex = $self->{vertex};
	my $face   = $self->{face};

	# Render the faces
	my @voga = ();
	foreach my $f ( @$face ) {
		my $t = $f->[0];

		if ( $t == 4 ) {
			# Quad
			push @voga, (
				@{$vertex->[$f->[2]]},
				@{$vertex->[$f->[3]]},
				@{$vertex->[$f->[4]]},
				@{$vertex->[$f->[5]]},
			);
		}

	}

	return {
		vertex => OpenGL::Array->new_list(
			OpenGL::GL_FLOAT,
			@voga,
		),
	};
}

1;
