package SDL::Tutorial::3DWorld::Model;

=pod

=head1 NAME

SDL::Tutorial::3DWorld::Model - Generic support for on disk model parsers

=head1 SYNOPSIS

  # Create the object but don't load anything
  my $model = SDL::Tutorial::3DWorld::Model->new(
      file => 'mymodel.rwx',
  );
  
  # Load the model into OpenGL
  $model->init;
  
  # Render the model into the current scene
  $model->display;

=head1 DESCRIPTION

B<SDL::Tutorial::3DWorld::Model> provides shared functionality across all
of the different model file implementations.

=cut

use 5.008;
use strict;
use warnings;
use IO::File                       ();
use Params::Util                   ();
use OpenGL::List                   ();
use SDL::Tutorial::3DWorld::Asset  ();
use SDL::Tutorial::3DWorld::OpenGL ();

our $VERSION = '0.33';

# Global Model Cache.
# Since there are currently no optional model settings and model
# objects are immutable, we can do a simple file-based key for models.
our %CACHE = ();





######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Make sure the filename is absolute so we have consistent keys
	# for the global texture cache. Return from the cache if we can.
	my $key = File::Spec->rel2abs( $self->file );
	return $CACHE{$key} if $CACHE{$key};

	# Check param
	my $file  = $self->file;
	unless ( -f $file ) {
		die "The model file '$file' does not exists";
	}

	# Bootstrap a asset if we were not passed one.
	unless ( $self->{asset} ) {
		my $directory = $self->file;
		$directory =~ s/[\w\._-]+$//;
		$self->{asset} = SDL::Tutorial::3DWorld::Asset->new(
			directory => $directory,
		);
	}
	unless ( Params::Util::_INSTANCE($self->asset, 'SDL::Tutorial::3DWorld::Asset') ) {
		die "Missing or invalid asset";
	}

	# Save the new model to the global cache
	$CACHE{$key} = $self;

	return $self;
}

sub file {
	$_[0]->{file}
}

sub asset {
	$_[0]->{asset};
}

sub list {
	$_[0]->{list};
}





######################################################################
# Main Methods

sub init {
	my $self   = shift;
	unless ( defined $self->{list} ) {
		my $handle = IO::File->new( $self->file, 'r' );
		$self->{list} = $self->parse( $handle );
		$handle->close;
	}
	return 1;
}

sub parse {
	die "CODE INCOMPLETE";
}

sub display {
	OpenGL::glCallList( $_[0]->{list} );
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
