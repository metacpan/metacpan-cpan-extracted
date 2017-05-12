#
# Nintendo Wiimote controller class
#

package OpenGL::Earth::Wiimote;

use strict;
use Carp;

our $HAVE_WIIMOTE = 0;
our $HANDLE;

if ($^O =~ m{Linux}i) {
    eval 'use Linux::Input::Wiimote; $HAVE_WIIMOTE = 1;';
}

sub disconnect {
	my ($wii) = $HANDLE;
	$wii->disconnect();
}

sub fake_keys {
    my $keys = {};
}

sub get_keys {

	my ($wii) = $HANDLE;

    if (! $HAVE_WIIMOTE) {
        return fake_keys();
    }

	my $k = {};

    if ( $wii->get_wiimote_keys_home ) {
        $k->{home} = 1;
    }
    if ( $wii->get_wiimote_keys_up ) {
        $k->{up} = 1;
    }
    if ( $wii->get_wiimote_keys_down ) {
        $k->{down} = 1;
    }
    if ( $wii->get_wiimote_keys_left ) {
        $k->{left} = 1;
    }
    if ( $wii->get_wiimote_keys_right ) {
        $k->{right} = 1;
    }
    if ( $wii->get_wiimote_keys_a ) {
        $k->{'A'} = 1;
    }
    if ( $wii->get_wiimote_keys_b ) {
        $k->{'B'} = 1;
    }
    if ( $wii->get_wiimote_keys_1 ) {
        $k->{'1'} = 1;
    }
    if ( $wii->get_wiimote_keys_2 ) {
        $k->{'2'} = 1;
    }
    if ( $wii->get_wiimote_keys_minus ) {
        $k->{'-'} = 1;
    }
    if ( $wii->get_wiimote_keys_plus ) {
        $k->{'+'} = 1;
    }

	return $k;
}

sub fake_motion {

    my $motion = {
        axis_x => 0x7F,
        axis_y => 0x7F,
        axis_z => 0x7F,
        tilt_x => 0,
        tilt_y => 0,
        tilt_z => 0,
        force_x=> 1.0,
        force_y=> 0,
        force_z=> 0,
    };

    return $motion;
}

sub get_motion {

	my ($wii) = $HANDLE;

    # Return a fake no-motion struct
    if (! $HAVE_WIIMOTE) {
        return fake_motion();
    }

	$wii->wiimote_update();

	my $mt = {};

	$mt->{axis_x} = $wii->get_wiimote_axis_x();
    $mt->{axis_y} = $wii->get_wiimote_axis_y();
    $mt->{axis_z} = $wii->get_wiimote_axis_z();

	$mt->{tilt_x} = $wii->get_wiimote_tilt_x();
    $mt->{tilt_y} = $wii->get_wiimote_tilt_y();
    $mt->{tilt_z} = $wii->get_wiimote_tilt_z();

	$mt->{force_x} = $wii->get_wiimote_force_x();
    $mt->{force_y} = $wii->get_wiimote_force_y();
    $mt->{force_z} = $wii->get_wiimote_force_z();

	return $mt;
}

sub init {

    if (! $HAVE_WIIMOTE) {
        return;
    }

	my $wii = Linux::Input::Wiimote->new();
	my $addr = '00:1F:C5:06:5E:BB';

	my $connect = $wii->wiimote_connect($addr);
	if ($connect == -1 ) {
		carp "Can't connect to Wiimote at $addr\n";
	}

	# Init wiimote to receive appropriate sensors data
	$wii->wiimote_update();
	$wii->set_wiimote_rumble(0);
	$wii->set_wiimote_ir(1);
	$wii->activate_wiimote_accelerometer();

	return ($HANDLE = $wii);
}

1;

