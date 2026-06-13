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
};

my $pi = $mod->new(label => 't/109-pwm_hw_mods.t', shm_key => 'rpit');

my $adc = $pi->adc(addr => 0x48);   # ADS1115 #1 (PWM feedback on ch 0)

if (! $ENV{NO_BOARD}) {

    my $pin = $pi->pin(PIN, 't/109-pwm_hw_mods.t');
    $pin->mode(INPUT);
    $pin->pull(PUD_DOWN);

    is $pin->mode, INPUT, "pin in INPUT ok";
    
    my $o; # analog input
   
    $o = $adc->percent(ANALOG);
    
    # double-check; same when we exit

    is $o < 1, 1, "before PWM hackery, output ok";
    #sleep 1;

    $pin->mode(PWM_OUT);

    $pi->pwm_mode(PWM_MODE_MS);
    $pi->pwm_clock(DIVISOR);
    $pi->pwm_range(RANGE);

    $pin->pwm(LEFT);


    #sleep 1;

    # Acceptance windows are single-sourced in t/RPiTest.pm
    # (rpi_pwm_adc_window(); shared with t/140-pwm_spi_adc.t) - recalibrate
    # there, not here. With this file's custom RANGE the helper returns the
    # duty-cycle model window, giving each cycle a real lower bound (the old
    # `>= -1` was unfailable) and a duty-tracking upper bound (the old flat
    # ceiling was 40)

    for (LEFT .. RIGHT){
        # sweep all the way left to right
        $pin->pwm($_);
        $o = $adc->percent(ANALOG);
        my ($min, $max) = rpi_pwm_adc_window($_, RANGE);
        cmp_ok $o, '>=', $min, "output >= $min on cycle $_ going right ok";
        cmp_ok $o, '<=', $max, "output <= $max on cycle $_ going right ok";
        select(undef, undef, undef, DELAY);
    }

    #sleep 1;

    for (reverse LEFT .. RIGHT){
        # sweep all the way right to left
        $pin->pwm($_);
        $o = $adc->percent(ANALOG);
        my ($min, $max) = rpi_pwm_adc_window($_, RANGE);
        cmp_ok $o, '>=', $min, "output >= $min on cycle $_ going left ok";
        cmp_ok $o, '<=', $max, "output <= $max on cycle $_ going left ok";
        select(undef, undef, undef, DELAY);
    }

    #sleep 1;

    $pi->pwm_mode(PWM_MODE_BAL);
    $pi->pwm_clock(32);
    $pi->pwm_range(1023);
    $pin->pwm(0);
    $pin->mode(INPUT);
    $pin->pull(PUD_DOWN);

    #sleep 1;
    
    # let's double-check

    $o = $adc->percent(ANALOG);
    is $o < 1, 1, "PWM pin cleaned up ok";
    #sleep 1;
    $o = $adc->percent(ANALOG);
    is $o < 1, 1, "PWM pin cleaned up ok";

    is $pin->mode, INPUT, "PWM pin back to INPUT ok";

}

# rpi_check_pin_status();

$pi->cleanup;

rpi_check_pin_status();
#rpi_metadata_clean();

done_testing();
