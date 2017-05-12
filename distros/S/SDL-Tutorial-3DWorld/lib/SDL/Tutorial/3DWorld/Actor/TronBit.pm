package SDL::Tutorial::3DWorld::Actor::TronBit;


=pod

=head1 NAME

SDL::Tutorial::3DWorld::Actor::TronBit - An attempt to create "Bit" from Tron

=head1 DESCRIPTION

An attempt to make a complex actor, the "bit" character from tron.

Contains multiple sub-models, continually morphing and moving as a whole.

B<THIS CLASS DOES NOT WORK, AND ACTS ONLY AS A PLACEHOLDER FOR FUTURE WORK>

=cut

use 5.008;
use strict;
use warnings;
use OpenGL                           ();
use SDL::Tutorial::3DWorld::OpenGL   ();
use SDL::Tutorial::3DWorld::Actor    ();
use SDL::Tutorial::3DWorld::Material ();

our $VERSION = '0.33';
our @ISA     = 'SDL::Tutorial::3DWorld::Actor';

use constant D2R => CORE::atan2(1,1) / 45;





######################################################################
# Constructor

sub new {
	my $self = shift->SUPER::new(
		# orient   => [ 0.0, 0.0, 1.0, 0.0 ],
		# rotate   => 1,
		@_,
	);

	# Force a zero velocity so we get the move call
	$self->{velocity} ||= [ 0, 0, 0 ];

	# "No" is a harsh metallic 27th icosahedron
	$self->{no_cycle}    = 0;   # Position in the "No" cycle if active
	$self->{no_duration} = 0.5; # Total duration of the "No" cycle
	$self->{no_material} = SDL::Tutorial::3DWorld::Material->new(
		shininess => 120,
		specular  => [ 1.0, 1.0, 1.0, 1.0 ],
		diffuse   => [ 0.5921, 0.0167, 0.0000, 1.0 ],
		ambient   => [ 0.1985, 0.0000, 0.0000, 1.0 ],
	);

	# "Yes" is a flat yellow tetrahedron
	$self->{yes_cycle}    = 0;   # Position in the "Yes" cycle if active
	$self->{yes_duration} = 0.5; # Total duration of the "Yes" cycle
	$self->{yes_material} = SDL::Tutorial::3DWorld::Material->new(
		# shininess => 100.2235,
		# specular  => [ 1.0,    1.0,    1.0,    1.0 ],
		diffuse   => [ 0.0167, 0.5921, 0.0000, 1.0 ],
		ambient   => [ 0.0000, 0.1985, 0.0000, 1.0 ],
	);

	# The main body is a slowly rotating light blue metallic icosahedron
	$self->{null_angle}    = 0;
	$self->{null_speed}    = 1;
	$self->{null_material} = SDL::Tutorial::3DWorld::Material->new(
		shininess => 120,
		specular  => [ 1.0, 1.0, 1.0, 1.0 ],
		diffuse   => [ 0.7, 0.7, 1.0, 1.0 ],
		ambient   => [ 0.3, 0.3, 1.0, 1.0 ],
	);

	return $self;
}





######################################################################
# External Methods

sub yes {
	my $self = shift;

	# Trigger the "Yes" cycle
	$self->{yes_cycle} = 0.1;
	$self->{no_cycle}  = 0;

	return 1;
}

sub no {
	my $self = shift;

	# Trigger the "No" cycle
	$self->{no_cycle}  = 0.1;
	$self->{yes_cycle} = 0;

	return 1;
}





######################################################################
# Engine Methods

sub init {
	my $self = shift;

	# Initialise the materials
	$self->{no_material}->init;
	$self->{yes_material}->init;
	$self->{null_material}->init;

	return 1;
}

sub move {
	my $self = shift;
	my $step = $_[0];
	$self->SUPER::move(@_);

	# Rotate the rest body angle (fairly quickly)
	$self->{null_angle} = (
		$self->{null_angle} + $self->{null_speed} * $step
	) % 360;

	# If we are in the "No" or "Yes" cycle advance and (maybe) end them
	if ( $self->{no_cycle} ) {
		$self->{no_cycle} += ($step * 36 / $self->{no_duration});
		$self->{no_cycle} = 0 if $self->{no_cycle} >= 360;
	}
	if ( $self->{yes_cycle} ) {
		$self->{yes_cycle} += ($step * 36 / $self->{yes_duration});
		$self->{yes_cycle} = 0 if $self->{yes_cycle} >= 360;
	}

	return 1;
}

sub display {
	my $self = shift;

	# Do general transforms for the overall character
	$self->SUPER::display(@_);

	# Most parts of bit's body change in size,
	# so enable normalisation to avoid surface normal problems.
	OpenGL::glEnable( OpenGL::GL_NORMALIZE );

	# Set the size of the overall actor via a matric,
	# because the glut constructor commands only build at one size.
	### NOTE: Replace with proper size later.
	OpenGL::glScalef( 0.3, 0.3, 0.3 );

	# The size of the null rest body, which moves along
	# a "1.01 - sin" curve (the 0.01 avoids divide by zero).
	my $null = 1;

	if ( $self->{yes_cycle} ) {
		# The size of "Yes" moves on a 180 degree sin curve
		my $yes = sin($self->{yes_cycle} * D2R / 2);
		$null = (1 - $yes) ** 2 || 0.01;

		# Draw the "Yes" octahedron, which never rotates.
		$self->{yes_material}->display;
		OpenGL::glPushMatrix();
		OpenGL::glScalef( $yes * 1.5, $yes * 1.5, $yes * 1.5 );
		OpenGL::glutSolidOctahedron();
		OpenGL::glPopMatrix();
	}

	if ( $self->{no_cycle} ) {
		# The size of "No" moves on a 180 degree sin curve
		my $no = sin($self->{no_cycle} * D2R / 2);
		$null = (1 - $no) ** 2 || 0.01;

		# Draw the "No" 27th icosahedron thingy, which never rotates.
		$self->{no_material}->display;
		OpenGL::glPushMatrix();
		OpenGL::glScalef( $no * 1.5, $no * 1.5, $no * 1.5 );
		OpenGL::glutSolidTetrahedron();
		OpenGL::glPopMatrix();
	}

	# The rest of the body elements in the null state rotate
	$self->{null_material}->display;
	OpenGL::glScalef( $null, $null, $null ) unless $null == 1;
	# OpenGL::glRotatef( $self->{null_angle}, 0, 1, 0 );

	# Show the icosahedron
	OpenGL::glPushMatrix();
	OpenGL::glRotatef( $self->{null_angle}, 1, 0, 0 );
	OpenGL::glutSolidIcosahedron();
	OpenGL::glPopMatrix();

	# Show the dodecahedron
	OpenGL::glPushMatrix();
	OpenGL::glScalef( 0.55, 0.55, 0.55 );
	OpenGL::glutSolidDodecahedron();
	OpenGL::glPopMatrix();

	# Done with these resizing games
	OpenGL::glDisable( OpenGL::GL_NORMALIZE );

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
