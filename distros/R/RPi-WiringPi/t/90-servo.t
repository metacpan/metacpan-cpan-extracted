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


if (! $ENV{NO_BOARD}) {
    my $pi = $mod->new;

    my $adc = $pi->adc;

    my $servo = $pi->servo(18);
    my $o;

    $servo->pwm(LEFT);

    for (LEFT .. RIGHT){
        # sweep all the way left to right
        $servo->pwm($_);
        $o = $adc->percent(ANALOG);
        is $o >= -1, 1, "output ok on cycle $_ on right";
        is $o < MAX_IN, 1, "output ok on cycle $_ on right\n";
        select(undef, undef, undef, DELAY);
    }

    for (reverse LEFT .. RIGHT){
        # sweep all the way right to left
        $servo->pwm($_);
        $o = $adc->percent(ANALOG);
        is $o >= -1, 1, "output ok on cycle $_ on left";
        is $o < MAX_IN, 1, "output ok on cycle $_ on left\n";
        select(undef, undef, undef, DELAY);
    }

    $pi->cleanup;
    
    $o = $adc->percent(ANALOG);
    is $o < 1, 1, "PWM pin cleaned up ok";
    $o = $adc->percent(ANALOG);
    is $o < 1, 1, "PWM pin cleaned up ok";

    check_pin_status();

}

done_testing();
