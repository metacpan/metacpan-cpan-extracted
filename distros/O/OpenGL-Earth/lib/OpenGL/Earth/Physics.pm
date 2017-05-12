#
# Acceleration, speed, and rotation of the Earth
#
# $Id$

package OpenGL::Earth::Physics;

use strict;
use warnings;
use OpenGL;
use OpenGL::Earth::Wiimote;

our $X_ROT = 300.0;
our $Y_ROT = 0.0;

our $X_SPEED = 0.0;
our $Y_SPEED = 0.02;

our $Z_OFF   = -5.0;


sub calculate_falloff_motion {

	my ($motion) = @_;

	my $falloff_factor = 0.96;
	my $acc = abs($motion->{force_x} / 10);

    my $keys = OpenGL::Earth::Wiimote::get_keys();
	my $acc_pos = exists $keys->{A};
	my $home = exists $keys->{home};

	if ($home) {
		$X_ROT = 300.0;
		$Y_ROT = 0.0;
		$X_SPEED = 0.0;
		$Y_SPEED = 0.02;
		return;
	}

	if (exists $keys->{up}) {
		$Z_OFF -= 0.01;
	}
	if (exists $keys->{down}) {
		$Z_OFF += 0.01;
	}

	if ($acc_pos) {
		$X_SPEED += $acc * ($X_SPEED > 0 ? 1 : -1);
		$Y_SPEED += $acc * ($Y_SPEED > 0 ? 1 : -1);
	}
	else {
		$X_SPEED += $motion->{tilt_z} * $acc;
		$Y_SPEED += $motion->{tilt_y} * $acc;
	}

	if ($X_SPEED > 5) { $X_SPEED = 5 }
	if ($Y_SPEED > 5) { $Y_SPEED = 5 }

	$X_ROT += $X_SPEED;
	$Y_ROT += $Y_SPEED;

    if ($X_SPEED > 0.02) {
	    $X_SPEED *= $falloff_factor;
    }

    if ($Y_SPEED > 0.02) {
	    $Y_SPEED *= $falloff_factor;
    }

	return;
}

{
	my $prev_tilt_x = 0.0;
	my $prev_tilt_y = 0.0;

	sub calculate_static_motion {

		my ($motion) = @_;

		# Now let's do the motion calculations.
		$X_SPEED = ($motion->{tilt_z} - $prev_tilt_x) / 2;
		$Y_SPEED = ($motion->{tilt_y} - $prev_tilt_y) / 2;

		$prev_tilt_x = $X_SPEED;
		$prev_tilt_y = $Y_SPEED;

		$X_ROT += $X_SPEED;
		$Y_ROT += $Y_SPEED;

		return;
	}

}

sub move {

    # Move the object back from the screen.
    glTranslatef(0.0,0.0,$Z_OFF);

    # Rotate the calculated amount.
    glRotatef($X_ROT,1.0,0.0,0.0);
    glRotatef($Y_ROT,0.0,0.0,1.0);

    return;
}

sub reverse_motion {
    $X_SPEED = -$X_SPEED;
    $Y_SPEED = -$Y_SPEED;
    return;
}

sub stop {
    $X_SPEED = $Y_SPEED = 0.0;
    return;
}

1;
