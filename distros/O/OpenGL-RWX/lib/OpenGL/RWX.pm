package OpenGL::RWX;

=pod

=head1 NAME

OpenGL::RWX - Provides support for loading 3D models from RWX files

=head1 SYNOPSIS

  # Create the object but don't load anything
  my $model = OpenGL::RWX->new(
      file => 'mymodel.rwx',
  );
  
  # Load the model into OpenGL
  $model->init;
  
  # Render the model into the current scene
  $model->display;

=head1 DESCRIPTION

B<OpenGL::RWX> provides a basic implementation of a RWX file parser.

Given a file name, it will load the file and parse the contents directly
into a compiled OpenGL display list.

The OpenGL display list can then be executed directly from the RWX object.

The current implementation is extremely preliminary and functionality will
be gradually fleshed out over time.

In this initial test implementation, the model will only render as a set of
points in space using the pre-existing material settings.

=cut

use 5.008;
use strict;
use warnings;
use IO::File     1.14 ();
use File::Spec   3.31 ();
use OpenGL       0.64 ':all';
use OpenGL::List 0.01 ();

our $VERSION = '0.02';





######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check param
	my $file  = $self->file;
	unless ( -f $file ) {
		die "RWX model file '$file' does not exists";
	}

	# Texture cache
	$self->{textures} = { };

	return $self;
}

sub file {
	$_[0]->{file}
}

sub list {
	$_[0]->{list};
}





######################################################################
# Main Methods

sub display {
	glCallList( $_[0]->{list} );
}

sub init {
	my $self   = shift;
	my $handle = IO::File->new( $self->file, 'r' );
	$self->parse( $handle );
	$handle->close;
	return 1;
}





######################################################################
# Parsing Methods

sub parse {
	my $self   = shift;
	my $handle = shift;

	# Set up the (Perl) vertex array.
	# The vertex list starts from position 1, so prepad a null
	my @color   = ( 0, 0, 0 );
	my $ambient = 0;
	my $diffuse = 1;
	my $opacity = 1;
	my @vertex  = ( undef );
	my $begin   = undef;

	# Start the list context
	$self->{list} = OpenGL::List::glpList {
		# Start without texture support and reset specularity
		glEnable( GL_LIGHTING );
		glDisable( GL_TEXTURE_2D );
		OpenGL::glMaterialf( GL_FRONT, GL_SHININESS, 128 );
		OpenGL::glMaterialfv_p( GL_FRONT, GL_SPECULAR, 1, 1, 1, 1 );
		OpenGL::glMaterialfv_p(
			GL_FRONT,
			GL_AMBIENT,
			( map { $_ * $ambient } @color ),
			$opacity,
		);
		OpenGL::glMaterialfv_p(
			GL_FRONT,
			GL_DIFFUSE,
			( map { $_ * $diffuse } @color ),
			$opacity,
		);

		while ( 1 ) {
			my $line = $handle->getline;
			last unless defined $line;

			# Remove blank lines, trailing whitespace and comments
			$line =~ s/\s*(?:#.+)[\012\015]*\z//;
			$line =~ m/\S/ or next;

			# Parse the dispatch the line
			my @words   = split /\s+/, $line;
			my $command = lc shift @words;
			if ( $command eq 'vertex' or $command eq 'vertexext' ) {
				# Only take the first three values, ignore any uv stuff
				push @vertex, [ @words[0..2] ];

			} elsif ( $command eq 'color' ) {
				@color = @words;
				OpenGL::glMaterialfv_p(
					GL_FRONT,
					GL_AMBIENT,
					( map { $_ * $ambient } @color ),
					$opacity,
				);
				OpenGL::glMaterialfv_p(
					GL_FRONT,
					GL_DIFFUSE,
					( map { $_ * $diffuse } @color ),
					$opacity,
				);

			} elsif ( $command eq 'ambient' ) {
				$ambient = $words[0];
				OpenGL::glMaterialfv_p(
					GL_FRONT,
					GL_AMBIENT,
					( map { $_ * $ambient } @color ),
					$opacity,
				);
				OpenGL::glMaterialfv_p(
					GL_FRONT,
					GL_DIFFUSE,
					( map { $_ * $diffuse } @color ),
					$opacity,
				);

			} elsif ( $command eq 'diffuse' ) {
				$diffuse = $words[0];
				OpenGL::glMaterialfv_p(
					GL_FRONT,
					GL_AMBIENT,
					( map { $_ * $ambient } @color ),
					$opacity,
				);
				OpenGL::glMaterialfv_p(
					GL_FRONT,
					GL_DIFFUSE,
					( map { $_ * $diffuse } @color ),
					$opacity,
				);

			} elsif ( $command eq 'triangle' ) {
				# Switch to triangle drawing mode if needed
				glEnd() if defined $begin;
				glBegin( GL_TRIANGLES );
				$begin = 'triangle';

				# Set the surface normal
				my @v0 = @{$vertex[$words[0]]};
				my @v1 = @{$vertex[$words[1]]};
				my @v2 = @{$vertex[$words[2]]};
				glNormal9f( @v0, @v1, @v2 );

				# Draw the triangle polygon
				glVertex3f( @v0 );
				glVertex3f( @v1 );
				glVertex3f( @v2 );

			} elsif ( $command eq 'quad' ) {
				# Switch to quad drawing mode if needed
				glEnd() if defined $begin;
				glBegin( GL_QUADS );
				$begin = 'quad';

				# Set the surface normal
				my @v0 = @{$vertex[$words[0]]};
				my @v1 = @{$vertex[$words[1]]};
				my @v2 = @{$vertex[$words[2]]};
				glNormal9f( @v0, @v1, @v2 );

				# Draw the quad polygon
				glVertex3f( @v0 );
				glVertex3f( @v1 );
				glVertex3f( @v2 );
				glVertex3f( @{$vertex[$words[3]]} );

			} elsif ( $command eq 'protoend' ) {
				# End of the prototype, end drawing.
				glEnd() if defined $begin;

				# Reset state
				@color   = ( 0, 0, 0 );
				$ambient = 0;
				$diffuse = 1;
				$opacity = 1;
				@vertex  = ( undef );
				$begin   = undef;

				# Reset material
				OpenGL::glMaterialfv_p(
					GL_FRONT,
					GL_AMBIENT,
					( map { $_ * $ambient } @color ),
					$opacity,
				);
				OpenGL::glMaterialfv_p(
					GL_FRONT,
					GL_DIFFUSE,
					( map { $_ * $diffuse } @color ),
					$opacity,
				);

			} else {
				# Unsupported command, silently ignore
			}
		}

		# Terminate drawing mode if we're still in it
		glEnd() if defined $begin;
	};

	return 1;
}

# Calculate a surface normal
sub glNormal9f {
	my ($x0, $y0, $z0, $x1, $y1, $z1, $x2, $y2, $z2) = @_;

	# Calculate vectors A and B
	my $xa = $x0 - $x1;
	my $ya = $y0 - $y1;
	my $za = $z0 - $z1;
	my $xb = $x1 - $x2;
	my $yb = $y1 - $y2;
	my $zb = $z1 - $z2;

	# Calculate the cross product
	my $xn = ($ya * $zb) - ($za * $yb);
	my $yn = ($za * $xb) - ($xa * $zb);
	my $zn = ($xa * $yb) - ($ya * $xb);

	# Normalise the cross product
	my $l = sqrt( ($xn * $xn) + ($yn * $yn) + ($zn * $zn) ) || 1;
	glNormal3f( $xn / $l, $yn / $l, $zn / $l );
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=OpenGL-RWX>

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<OpenGL>

=head1 COPYRIGHT

Copyright 2010 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
