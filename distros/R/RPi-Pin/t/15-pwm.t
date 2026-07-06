use strict;
use warnings;

use RPi::Pin;
use RPi::Const qw(:all);
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
        $pin->mode(PWM_OUT);

        # GPIO 18 hardware PWM reads back via get_alt() as ALT5 (2) on the
        # legacy BCM boards (Pi 1-4) and ALT3 (7) on the Pi 5 / RP1

        my $alt = $pin->mode;
        ok $alt == ALT5 || $alt == ALT3,
            "pin mode set to PWM ok, and we can read it ($alt)";

        # Regression guard for the RP1: pwm() must accept a write once the pin
        # is in PWM mode, on every board. The old pin-18 guard compared
        # get_alt() against PWM_OUT (2) and wrongly died on the Pi 5, where the
        # PWM alt reads back as ALT3 (7), not PWM_OUT.
        ok eval { $pin->pwm(512); 1 },
            "pwm() accepts a write while the pin is in PWM mode";
        $pin->pwm(0);

        $pin->mode(INPUT);
        is $pin->mode, INPUT, "pin mode set back to INPUT";
    }
}

done_testing();
