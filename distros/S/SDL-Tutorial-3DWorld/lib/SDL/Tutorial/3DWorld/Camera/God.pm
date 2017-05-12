package SDL::Tutorial::3DWorld::Camera::God;

=pod

=head1 NAME

SDL::Tutorial::3DWorld::Camera::God - A "God Mode" flying person camera

=head1 DESCRIPTION

A flying-mode camera is a camera in which the "move" direction occurs in
three dimensions rather than two dimensions.

In addition, a different set of movement modifiers apply to a flying
camera than apply to a plain or walking camera.

=head1 METHODS

=cut

use 5.008;
use strict;
use warnings;
use OpenGL;
use SDL::Mouse;
use SDL::Constants                 ();
use SDL::Tutorial::3DWorld::Camera ();

our $VERSION = '0.33';
our @ISA     = 'SDL::Tutorial::3DWorld::Camera';

use constant D2R => CORE::atan2(1,1) / 45;

sub new {
	my $self = shift->SUPER::new(@_);
	my $down = $self->{down};

	# Store the original speed for later
	$self->{speed_original} = $self->{speed};

	# Move camera forwards and backwards
	$down->{SDL::Constants::SDLK_w} = 0;
	$down->{SDL::Constants::SDLK_s} = 0;

	# Strafe camera left and right
	$down->{SDL::Constants::SDLK_a} = 0;
	$down->{SDL::Constants::SDLK_d} = 0;

	# Lift up and down
	$down->{SDL::Constants::SDLK_SPACE} = 0;
	$down->{SDL::Constants::SDLK_LCTRL} = 0;

	# Shift makes us run
	$down->{SDL::Constants::SDLK_LSHIFT} = 0;

	return $self;
}





######################################################################
# Engine Interface

sub move {
	my $self  = shift;
	my $step  = shift;
	my $down  = $self->{down};

	# The shift key will allow continuous exponential
	# acceleration of around 5% per second.
	if ( $down->{SDL::Constants::SDLK_LSHIFT} ) {
		$self->{speed} += $self->{speed} * 0.05 * $step;
	} else {
		$self->{speed} = $self->{speed_original};
	}

	# To prevent angle-running and other tricks we need to find and
	# normalise the direction of movement before applying our speed.
	my $move   = $down->{SDL::Constants::SDLK_w}
	           - $down->{SDL::Constants::SDLK_s};
	my $strafe = $down->{SDL::Constants::SDLK_d}
	           - $down->{SDL::Constants::SDLK_a};
	my $lift   = $down->{SDL::Constants::SDLK_SPACE}
	           - $down->{SDL::Constants::SDLK_LCTRL};

	# Apply this movement in the direction of the camera.
	# Math applied unoptimised and longhand for greater readability.
	my $angle     = $self->{angle}     * D2R;
	my $elevation = $self->{elevation} * D2R;
	my $VX        = 0;
	my $VY        = 0;
	my $VZ        = 0;
	   $VX       += $move * sin($angle) * cos($elevation);
	   $VY       += $move * sin($elevation);
	   $VZ       += $move * -cos($angle) * cos($elevation);
	   $VX       += $strafe * cos($angle);
	   $VY       += $strafe * 0;
	   $VZ       += $strafe * sin($angle);
	   $VX       += $lift * sin($elevation) * -sin($angle);
	   $VY       += $lift * cos($elevation);
	   $VZ       += $lift * sin($elevation) * cos($angle);
	   
	# Normalise the velocity and apply to the position delta
	my $VL = sqrt( $VX ** 2 + $VY ** 2 + $VZ ** 2 ) || 1;
	my $VS = $self->{speed} * $step / $VL;

	# Apply the final velocity to the position
	$self->{X} += $VX * $VS;
	$self->{Y} += $VY * $VS;
	$self->{Z} += $VZ * $VS;

	# Clip to the zero plain (plus our "height")
	$self->{Y} = 1.5 if $self->{Y} < 1.5;

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
