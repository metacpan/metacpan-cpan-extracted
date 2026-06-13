use strict;
use warnings;

use RPi::Pin;
use Test::More;

my $mod = 'RPi::Pin';

if (! $ENV{RPI_SUBMODULE_TESTING}){
    plan(skip_all => "RPI_SUBMODULE_TESTING environment variable not set");
}

if ($> == 0){
    $ENV{RPI_BOARD} = 1;
}

if (! $ENV{RPI_BOARD}){
    warn "\n*** RPI_BOARD is not set! ***\n";
    $ENV{NO_BOARD} = 1;
    plan skip_all => "not on a pi board\n";
}

if ($> != 0){
    print "enforcing sudo for PWM tests...\n";
    # Re-exec with $^X (the running perl) so sudo doesn't fall back to the
    # system perl, which lacks our perlbrew-installed prerequisites; sudo
    # scrubs the environment, so re-feed the gate var via env(1)
    system(
        "sudo", "env", "RPI_SUBMODULE_TESTING=$ENV{RPI_SUBMODULE_TESTING}",
        $^X, "-I", "blib/lib", "-I", "blib/arch", $0
    );
    exit;
}

{# pwm

    if (! $ENV{NO_BOARD}) {
        my $pin = $mod->new(18);
        $pin->mode(2);

        # GPIO 18 hardware PWM is ALT5 (2) on Pi 1-4, ALT3 (7) on Pi 5

        my $alt = $pin->mode;
        ok $alt == 2 || $alt == 7, "pin mode set to PWM ok, and we can read it ($alt)";
        $pin->mode(0);
        is $pin->mode, 0, "pin mode set back to INPUT";
    }
}

done_testing();
