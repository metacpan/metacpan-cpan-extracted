package SDL::Tutorial::3DWorld::Actor::MaterialSampler;

=pod

=head1 NAME

SDL::Tutorial::3DWorld::Actor::MaterialSampler - A demonstrator for MTL files

=head1 DESCRIPTION

A B<MaterialSampler> is a grid of shapes designed to show off the properties
of different materials.

=cut

use 5.008;
use strict;
use warnings;
use OpenGL::List                       ();
use SDL::Tutorial::3DWorld::OpenGL     ();
use SDL::Tutorial::3DWorld::Actor      ();
use SDL::Tutorial::3DWorld::MTL ();
use SDL::Tutorial::3DWorld::Bound      ();

our $VERSION = '0.33';
our @ISA     = 'SDL::Tutorial::3DWorld::Actor';

sub new {
	my $self = shift->SUPER::new(@_);

	# Were we passed a MTL filename
	unless ( -f $self->file ) {
		die "Did not provide a MTL file";
	}

	# Material samples might contain transparent materials that need blending
	# $self->{blending} = 1;

	# Scaling and rotation are not supported
	if ( $self->{scale} ) {
		die "MaterialSampler actors do not support scaling";
	}
	if ( $self->{orient} ) {
		die "MaterialSampler actors do not support rotation";
	}

	return $self;
}

sub file {
	$_[0]->{file};
}





######################################################################
# Engine Interface

sub init {
	my $self = shift;

	# Load the material file
	$self->{mtl} = SDL::Tutorial::3DWorld::MTL->new(
		file => $self->{file},
	) or die "Failed to load MTL file";

	# Initialise the material file
	$self->{mtl}->init;

	# Fully initialise all materials and set up positions
	# for their material spheres.
	my $i = 0;
	$self->{mtlpos} = { };
	foreach my $name ( $self->{mtl}->names ) {
		$self->{mtl}->material($name)->init;
		$self->{mtlpos}->{$name} = [
			$self->{position}->[0] + ($i++ * 2),
			$self->{position}->[1],
			$self->{position}->[2],
		];
	}

	# Define the boundary box if the object is static
	unless ( $self->{velocity} ) {
		my $L = 2 * (scalar $self->{mtl}->names - 1);
		$self->{bound} = SDL::Tutorial::3DWorld::Bound->box(
			-0.5,      -0.5, -0.5,
			 0.5 + $L,  0.5,  0.5,
		);
	}

	return 1;
}

sub display {
	my $self = shift;

	# Calculate the order we'll render the spheres.
	# This ensures that anything transparent is blended properly.
	my @names = $self->{mtl}->names;
	my @order = SDL::Tutorial::3DWorld->current->camera->distance_isort(
		map { $self->{mtlpos}->{$_} } @names
	);

	# Iterate over the materials
	foreach my $i ( @order ) {
		my $name = $names[$i];
		$self->{mtl}->material($name)->display;
		OpenGL::glPushMatrix();
		OpenGL::glTranslatef( @{$self->{mtlpos}->{$name}} );
		OpenGL::glutSolidSphere( 0.5, 50, 50 );
		OpenGL::glPopMatrix();
	}

	return 1;
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
