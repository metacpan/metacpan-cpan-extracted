package SDL::Tutorial::3DWorld::OBJ;

=pod

=head1 NAME

SDL::Tutorial::3DWorld::OBJ - Support for loading 3D models from OBJ files

=head1 SYNOPSIS

  # Create the object but don't load anything
  my $model = SDL::Tutorial::3DWorld::OBJ->new(
      file => 'mymodel.obj',
  );
  
  # Load the model into OpenGL
  $model->init;
  
  # Render the model into the current scene
  $model->display;

=head1 DESCRIPTION

B<SDL::Tutorial::3DWorld::OBJ> provides a basic implementation of a OBJ file
parser.

Given a file name, it will load the file and parse the contents directly
into a compiled OpenGL display list.

The OpenGL display list can then be executed directly from the OBJ object.

The current implementation is extremely preliminary and functionality will
be gradually fleshed out over time.

In this initial test implementation, the model will only render as a set of
points in space using the pre-existing material settings.

=cut

use 5.008;
use strict;
use warnings;
use IO::File                      ();
use File::Spec                    ();
use SDL::Tutorial::3DWorld::Mesh  ();
use SDL::Tutorial::3DWorld::Asset ();
use SDL::Tutorial::3DWorld::Model ();

our $VERSION = '0.33';
our @ISA     = 'SDL::Tutorial::3DWorld::Model';





######################################################################
# Parsing Methods

sub parse {
	my $self   = shift;
	my $handle = shift;
	my $mesh   = SDL::Tutorial::3DWorld::Mesh->new;
	my $m      = 0; # Material index position

	# Fill the mesh
	while ( 1 ) {
		my $line = $handle->getline;
		last unless defined $line;

		# Remove blank lines, trailing whitespace and comments
		$line =~ s/\s*(?:#.+)[\012\015]*\z//;
		$line =~ m/\S/ or next;

		# Parse the dispatch the line
		my @words   = split /\s+/, $line;
		my $command = lc shift @words;
		if ( $command eq 'v' ) {
			# Create the vertex
			$mesh->add_vertex( @words );

		} elsif ( $command eq 'vt' ) {
			# Create the texture location.
			# We only support two-dimensional textures,
			# so don't pass more than two params.
			$mesh->add_uv( @words[0,1] );

		} elsif ( $command eq 'vn' ) {
			# Normal vectors might not be unit so we need to
			# unitise before we add it to the mesh.
			my $l = sqrt( $words[0] ** 2 + $words[1] ** 2 + $words[2] ** 2 );
			$mesh->add_normal(
				$words[0] / $l,
				$words[1] / $l,
				$words[2] / $l,
			);

		} elsif ( $command eq 'f' ) {
			if ( @words == 3 ) {
				my @i = map { split /\//, $_ } @words;
				if ( @i == 3 ) {
					# f v1 v2 v3
					$mesh->add_triangle( $m, @i );
				} elsif ( @i == 6 ) {
					# f v1/vt1 v2/vt2 v3/vt3
					$mesh->add_triangle( $m, @i[0,2,4,1,3,5] );
				} elsif ( @i == 9 ) {
					# f v1/vt1/vn1 v2/vt2/vn2 v3/vt3/vn3
					# f v1//vn1 v2//vn2 v3//vn3
					$mesh->add_triangle( $m, @i[0,3,6,1,4,7,2,5,8] );
				} else {
					die "Unsuppored face '$line'";
				}
			} elsif ( @words == 4 ) {
				my @i = map { split /\//, $_ } @words;
				if ( @i == 4 ) {
					# f v1 v2 v3 v4
					$mesh->add_quad( $m, @i );
				} elsif ( @i == 8 ) {
					# f v1/vt1 v2/vt2 v3/vt3 v4/vt4
					$mesh->add_quad( $m, @i[0,2,4,6,1,3,5,7] );
				} elsif ( @i == 12 ) {
					# f v1/vt1/vn1 v2/vt2/vn2 v3/vt3/vn3 v4/vt4/vn4
					# f v1//vn1 v2//vn2 v3//vn3 /v4//vn4
					$mesh->add_quad( $m, @i[0,3,6,9,1,4,7,10,2,5,8,11] );
				} else {
					die "Unsuppored face '$line'";
				}
			} else {
				die "Unsuppored face '$line'";
			}

		} elsif ( $command eq 'mtllib' and not $self->{plain} ) {
			# Load the mtllib
			my $mtl = $self->asset->mtl( $words[0] );
			$mtl->init;

		} elsif ( $command eq 'usemtl' and not $self->{plain} ) {
			# Load a material from the mtl file
			my $name   = shift @words;
			my $object = $self->asset->material($name);
			$m = $mesh->add_material($object);

		}
	}

	# Initialise the mesh elements that need it
	$mesh->init;
	$self->{box} = [ $mesh->box ];

	# Generate the display list
	return $mesh->as_list;
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
