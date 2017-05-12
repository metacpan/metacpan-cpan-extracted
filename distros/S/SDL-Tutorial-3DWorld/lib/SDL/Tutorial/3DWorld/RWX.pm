package SDL::Tutorial::3DWorld::RWX;

=pod

=head1 NAME

SDL::Tutorial::3DWorld::RWX - Support for loading 3D models from RWX files

=head1 SYNOPSIS

  # Create the object but don't load anything
  my $model = SDL::Tutorial::3DWorld::RWX->new(
      file => 'mymodel.rwx',
  );
  
  # Load the model into OpenGL
  $model->init;
  
  # Render the model into the current scene
  $model->display;

=head1 DESCRIPTION

B<SDL::Tutorial::3DWorld::RWX> provides a basic implementation of a RWX file
parser.

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
use IO::File                      ();
use File::Spec                    ();
use OpenGL                        ':all';
use OpenGL::List                  ();
use SDL::Tutorial::3DWorld::Mesh  ();
use SDL::Tutorial::3DWorld::Asset ();
use SDL::Tutorial::3DWorld::Model ();

our $VERSION = '0.33';
our @ISA     = 'SDL::Tutorial::3DWorld::Model';





######################################################################
# Parsing Methods

sub parse {
	my $self     = shift;
	my $handle   = shift;
	my $mesh     = SDL::Tutorial::3DWorld::Mesh->new;
	my $offset   = 0;
	my $material = 0;
	my $ambient  = undef;
	my $diffuse  = undef;

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
			# Create the vertex
			my @vertex = map { $_ * 10 } splice @words, 0, 3;
			my @normal = ( 0, 0, 0 );
			my @uv     = ( 0, 0 );
			if ( @words and lc $words[0] eq 'uv' ) {
				@uv = @words[1,2];
			}
			$mesh->add_all( \@vertex, \@uv, \@normal );

		} elsif ( $command eq 'color' ) {
			my %param = ( color => [ @words ] );
			$param{ambient} = $ambient if $ambient;
			$param{diffuse} = $diffuse if $diffuse;
			$material = $mesh->add_material( %param );

		} elsif ( $command eq 'ambient' ) {
			$material = $mesh->add_material(
				ambient => [ @words ],
			);
			$ambient = [ @words ];

		} elsif ( $command eq 'diffuse' ) {
			$material = $mesh->add_material(
				diffuse => [ @words ],
			);
			$diffuse = [ @words ],

		} elsif ( $command eq 'opacity' ) {
			$material = $mesh->add_material(
				opacity => $words[0],
			);
			if ( $words[0] < 1 ) {
				$self->{blending} = 1;
			}

		} elsif ( $command eq 'texture' ) {
			my $name    = shift @words;
			if ( $name eq 'null' ) {
				$material = $mesh->add_material(
					texture => undef,
				);
			} else {
				my $texture = $self->asset->texture($name);
				unless ( $texture ) {
					die "The texture '$name' does not exist";
				}
				$material = $mesh->add_material(
					texture => $texture,
				);
			}

		} elsif ( $command eq 'triangle' ) {
			# Add the triangle with the right offset
			@words = map { $_ + $offset } @words;
			$mesh->add_triangle(
				$material,
				@words,
				@words,
				@words,
			);

		} elsif ( $command eq 'quad' ) {
			# Add the quad with the right offset
			@words = map { $_ + $offset } @words;
			$mesh->add_quad(
				$material,
				@words,
				@words,
				@words,
			);

		} elsif ( $command eq 'protoend' ) {
			# Correct the offset
			$offset = $mesh->max_vertex;

		} else {
			# Unsupported command, silently ignore
		}
	};

	# Initialise the mesh elements that need it
	$mesh->init;
	$self->{box} = [ $mesh->box ];

	# Generate the display list
	return OpenGL::List::glpList {
		$mesh->display;
	};
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
