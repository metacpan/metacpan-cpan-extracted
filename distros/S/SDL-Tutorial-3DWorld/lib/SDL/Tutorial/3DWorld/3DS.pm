package SDL::Tutorial::3DWorld::3DS;

=pod

=head1 NAME

SDL::Tutorial::3DWorld::3DS - Support for loading 3D models from 3DS files

=head1 SYNOPSIS

  # Create the object but don't load anything
  my $model = SDL::Tutorial::3DWorld::3DS->new(
      file => 'mymodel.3ds',
  );
  
  # Load the model into OpenGL
  $model->init;
  
  # Render the model into the current scene
  $model->display;

=head1 DESCRIPTION

B<SDL::Tutorial::3DWorld::3DS> provides a basic implementation of a 3DS file
parser.

Given a file name, it will load the file and parse the contents directly
into a compiled OpenGL display list.

The OpenGL display list can then be executed directly from the 3DS object.

The current implementation is extremely preliminary and functionality will
be gradually fleshed out over time.

In this initial test implementation, the model will only render as a set of
points in space using the pre-existing material settings.

=cut

use 5.008;
use strict;
use warnings;
use IO::File                           ();
use File::Spec                         ();
use SDL::Tutorial::3DWorld::Mesh       ();
use SDL::Tutorial::3DWorld::Asset      ();
use SDL::Tutorial::3DWorld::Model      ();
use SDL::Tutorial::3DWorld::3DS::Chunk ();

our $VERSION = '0.33';
our @ISA     = 'SDL::Tutorial::3DWorld::Model';

# Chunk IDs
my %NAME2ID = (
	# Primary chunk
	MAIN3DS => '4d4d',
);
my %ID2NAME = map {
	$NAME2ID{$_} => $_
} %NAME2ID;





######################################################################
# Parsing Methods

sub parse {
	my $self   = shift;
	my $mesh   = SDL::Tutorial::3DWorld::Mesh->new;
	my $handle = shift;
	unless ( $handle->can('seek') ) {
		die "File handle is not seekable";
	}

	# Fetch the top chunk
	my $chunk = $self->chunk( $handle, 0 );
	my @stack = ( $chunk );
	while ( @stack ) {
		my $parent = $stack[-1];
		my $start  = $parent->child_start;
		my $child  = $self->chunk( $handle, $start );
		1;
	}

	# Initialise the mesh elements that need it
	$mesh->init;
	$self->{box} = [ $mesh->box ];

	# Generate the display list
	$mesh->as_list;
}

sub chunk {
	my $self   = shift;
	my $handle = shift;
	my $start  = shift;

	# Read the head block
	my $buffer = '';
	$handle->seek( $start, 0 );
	$handle->sysread( $buffer, 6 );

	# Parse the head block
	my ( $type, $bytes ) = unpack( 'H4 L', $buffer );
	return SDL::Tutorial::3DWorld::3DS::Chunk->new(
		type  => $type,
		start => $start,
		bytes => $bytes,
	);
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
