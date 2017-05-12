package SDL::Tutorial::3DWorld::Actor::Model;

=pod

=head1 NAME

SDL::Tutorial::3DWorld::Actor::Model - An actor loaded from a RWX file

=head1 SYNOPSIS

  # Define the model location
  my $model = SDL::Tutorial::3DWorld::Actor::Model->new(
      file => 'torus.rwx',
  );
  
  # Load and compile the model into memory
  $model->init;
  
  # Render the model into the current scene
  $model->display;

=head1 DESCRIPTION

This is an experimental module for loading large or complex shapes from
RWX model files on disk.

=cut

use 5.008;
use strict;
use warnings;
use OpenGL::List                  ();
use SDL::Tutorial::3DWorld        ();
use SDL::Tutorial::3DWorld::Actor ();
use SDL::Tutorial::3DWorld::OBJ   ();
use SDL::Tutorial::3DWorld::RWX   ();
use SDL::Tutorial::3DWorld::Bound;

our $VERSION = '0.33';
our @ISA     = 'SDL::Tutorial::3DWorld::Actor';

sub new {
	my $self = shift->SUPER::new(@_);

	# Map to the absolute disk file
	$self->{file} = SDL::Tutorial::3DWorld->sharefile( $self->{file} );
	unless ( -f $self->{file} ) {
		die "Model file '$self->{file}' does not exist";
	}

	# Create the type-specific object
	if ( $self->{file} =~ /\.rwx$/ ) {
		$self->{model} = SDL::Tutorial::3DWorld::RWX->new(
			file  => $self->{file},
		);

	} elsif ( $self->{file} =~ /\.obj$/ ) {
		$self->{model} = SDL::Tutorial::3DWorld::OBJ->new(
			file  => $self->{file},
			plain => $self->{plain},
		);

	} else {
		die "Unkown or unsupported file '$self->{file}'";
	}

	return $self;
}





######################################################################
# Engine Methods

sub init {
	my $self     = shift;
	my $model    = $self->{model};
	my $position = $self->{position};
	my $scale    = $self->{scale};
	my $orient   = $self->{orient};
	$self->SUPER::init(@_);

	# Load the model display list
	$model->init;

	# Do we need blending support?
	if ( $model->{blending} ) {
		$self->{blending} = 1;
	}

	# Get the bounding box from the model
	if ( $scale ) {
		$self->{bound} = SDL::Tutorial::3DWorld::Bound->box(
			$model->{box}->[0] * $scale->[0],
			$model->{box}->[1] * $scale->[1],
			$model->{box}->[2] * $scale->[2],
			$model->{box}->[3] * $scale->[0],
			$model->{box}->[4] * $scale->[1],
			$model->{box}->[5] * $scale->[2],
		);
	} else {
		$self->{bound} = SDL::Tutorial::3DWorld::Bound->box(
			@{ $model->{box} },
		);
	}

	# Static model optimisations
	unless ( $self->{velocity} ) {
		# Compile the entire display routine
		$self->{display} = OpenGL::List::glpList {
			OpenGL::glPushMatrix();
			OpenGL::glTranslatef( @$position );
			if ( $scale ) {
				# If we are going to be doing scaling (in GL) the underlying
				# matrix operations in OpenGL will screw up the normal vectors
				# and break the lighting badly.
				# We need to enable normalisation for this model. This makes the
				# drawing slower but prevents shading corruption.
				# If the object's scaling is going to be static (i.e. the object
				# won't be dynamically changing sizes) it is much better to do
				# the normal correction once in advance.
				# More details at the following URL.
				# http://www.opengl.org/resources/features/KilgardTechniques/oglpitfall/
				OpenGL::glEnable( OpenGL::GL_NORMALIZE );
				OpenGL::glScalef( @$scale );
				OpenGL::glRotatef( @$orient ) if $orient;
				OpenGL::glCallList( $model->{list} );
				OpenGL::glDisable( OpenGL::GL_NORMALIZE );
			} else {
				OpenGL::glRotatef( @$orient ) if $orient;
				OpenGL::glCallList( $model->{list} );
			}
			OpenGL::glPopMatrix();
		};
	}

	return 1;
}

sub display {
	my $self = shift;

	# Move to the correct location
	$self->SUPER::display(@_);

	# Render the model
	if ( $self->{scale} ) {
		# This is a repeat of the above for the non-optimised case
		OpenGL::glEnable( OpenGL::GL_NORMALIZE );
		$self->{model}->display;
		OpenGL::glDisable( OpenGL::GL_NORMALIZE );
	} else {
		$self->{model}->display;
	}

	return;
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

Copyright 2010 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
