use warnings;
use strict;

use RPi::Const qw(:all);
use WiringPi::API qw(:all);

die "need root!\n" if $> !=0;

use constant {
    LEFT    => 60,
    RIGHT   => 240,
    CENTRE  => 150,
    PIN     => 18,
    DIVISOR => 192,
    RANGE   => 2000,
    DELAY   => 0.01,
};

my $continue = 1;

$SIG{INT} = sub {
    $continue = 0;
    pwm_write(PIN, LEFT);
};

setup_gpio();

pin_mode(PIN, PWM_OUT);

pwm_set_mode(PWM_MODE_MS);
pwm_set_clock(DIVISOR);
pwm_set_range(RANGE);

# set the servo to left point

pwm_write(PIN, LEFT);
sleep 2;

while ($continue){
    for (LEFT .. RIGHT){
        # sweep all the way left to right
        pwm_write(PIN, $_);
        select(undef, undef, undef, DELAY);
    }

    sleep 1;

    for (reverse LEFT .. RIGHT){
        # sweep all the way right to left
        pwm_write(PIN, $_);
        select(undef, undef, undef, DELAY);
    }

    sleep 1;
}
