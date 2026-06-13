use strict;
use warnings;

use lib 't/';

use RPiTest;
use RPi::WiringPi;
use RPi::Const qw(:all);
use Test::More;

rpi_sudo_check();

my $mod = 'RPi::WiringPi';

if ($> == 0){
    $ENV{RPI_BOARD} = 1;
    $ENV{RPI_ADC}   = 1;
    $ENV{RPI_SERVO} = 1;
}

if (! $ENV{RPI_SERVO}){
    plan skip_all => "RPI_SERVO environment variable not set\n";
}

if (! $ENV{RPI_ADC}){
    plan skip_all => "RPI_ADC environment variable not set\n";
}

if (! $ENV{RPI_BOARD}){
    $ENV{NO_BOARD} = 1;
    plan skip_all => "Not on a Pi board\n";
}

if ($> != 0){
    print "enforcing sudo for PWM tests...\n";
    # Re-exec with $^X (the running perl) so sudo doesn't fall back to the
    # system perl, which lacks our perlbrew-installed prerequisites
    system("sudo", $^X, "-I", "blib/lib", $0);
    exit;
}

rpi_i2c_check();

rpi_running_test(__FILE__);

use constant {
    LEFT    => 60,
    RIGHT   => 255,
    CENTRE  => 150,
    PIN     => 18,
    DIVISOR => 192,
    RANGE   => 2000,
    DELAY   => 0.01,
    ANALOG  => 0,
    MAX_IN  => 40,
};


if (! $ENV{NO_BOARD}) {
    my $pi = $mod->new(label => 't/325-servo.t', shm_key => 'rpit');

    # Always release pin 18 even if the sweep croaks or we're interrupted
    # mid-run. A leaked registration in the shared meta poisons every later
    # test file that uses pin 18 (t/150, t/200-213, etc.)

    my $cleaned = 0;

    my $cleanup = sub {
        return if $cleaned;
        $cleaned = 1;
        $pi->cleanup;
    };

    local $SIG{INT}  = sub { $cleanup->(); exit 1; };
    local $SIG{TERM} = sub { $cleanup->(); exit 1; };

    my $adc = $pi->adc(addr => 0x48);   # ADS1115 #1 (servo feedback on ch 0)

    my $servo = $pi->servo(18);
    my $o;

    my $ok = eval {
        $servo->pwm(LEFT);

        # Poll (bounded ~6s) until the servo's feedback settles at LEFT -
        # two consecutive reads within half a percent of each other -
        # instead of a fixed sleep 5

        my $prev = $adc->percent(ANALOG);

        for (1 .. 60){
            select(undef, undef, undef, 0.1);
            my $cur = $adc->percent(ANALOG);
            last if abs($cur - $prev) < 0.5;
            $prev = $cur;
        }

        for (LEFT .. RIGHT){
            # Sweep all the way left to right
            $servo->pwm($_);
            $o = $adc->percent(ANALOG);
            is $o >= -1, 1, "output ok on cycle $_ on right";
            is $o < MAX_IN, 1, "output ok on cycle $_ on right\n";
            select(undef, undef, undef, DELAY);
        }

        for (reverse LEFT .. RIGHT){
            # Sweep all the way right to left
            $servo->pwm($_);
            $o = $adc->percent(ANALOG);
            is $o >= -1, 1, "output ok on cycle $_ on left";
            is $o < MAX_IN, 1, "output ok on cycle $_ on left\n";
            select(undef, undef, undef, DELAY);
        }

        1;
    };

    my $err = $@;

    $cleanup->();

    if ($ok) {
        $o = $adc->percent(ANALOG);
        is $o < 1, 1, "PWM pin cleaned up ok";
        $o = $adc->percent(ANALOG);
        is $o < 1, 1, "PWM pin cleaned up ok";
    }
    else {
        fail("servo sweep died before completion: $err");
    }

    rpi_check_pin_status();

}

rpi_check_pin_status();
#rpi_metadata_clean();

done_testing();
