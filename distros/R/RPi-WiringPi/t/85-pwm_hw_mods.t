use strict;
use warnings;

use lib 't/';

use RPiTest qw(check_pin_status);
use RPi::WiringPi;
use RPi::WiringPi::Constant qw(:all);
use Test::More;

my $mod = 'RPi::WiringPi';

if ($> == 0){
    $ENV{PI_BOARD} = 1;
}

if (! $ENV{PI_BOARD}){
    warn "\n*** PI_BOARD is not set! ***\n";
    $ENV{NO_BOARD} = 1;
    plan skip_all => "not on a pi board\n";
    exit;
}

if ($> != 0){
    print "enforcing sudo for PWM tests...\n";
    system('sudo', 'perl', $0);
    exit;
}

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

my $pi = $mod->new;

my $adc = $pi->adc;

if (! $ENV{NO_BOARD}) {

    my $pin = $pi->pin(PIN);
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

    for (LEFT .. RIGHT){
        # sweep all the way left to right
        $pin->pwm($_);
        $o = $adc->percent(ANALOG);
        is $o >= -1, 1, "output ok on cycle $_ on right";
        is $o < MAX_IN, 1, "output ok on cycle $_ on right\n";
        select(undef, undef, undef, DELAY);
    }

    #sleep 1;

    for (reverse LEFT .. RIGHT){
        # sweep all the way right to left
        $pin->pwm($_);
        $o = $adc->percent(ANALOG);
        is $o >= -1, 1, "output ok on cycle $_ on left";
        is $o < MAX_IN, 1, "output ok on cycle $_ on left\n";
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

check_pin_status();

$pi->cleanup;

done_testing();
