use warnings;
use strict;

use RPi::WiringPi;
use RPi::WiringPi::Constant qw(:all);

die "need root!\n" if $> !=0;

use constant {
    LEFT    => 60,
    RIGHT   => 255,
    CENTRE  => 150,
    PIN     => 18,
    DIVISOR => 192,
    RANGE   => 2000,
    DELAY   => 0.001,
};

# set up a signal handler for CTRL-C

my $run = 1;
$SIG{INT} = sub {
    $run = 0;
};

# create the Pi object

my $pi = RPi::WiringPi->new;

# create a signal pin, set mode to PWM output

my $s = $pi->pin(PIN);
$s->mode(PWM_OUT);

# configure PWM to 50Hz for the servo

$pi->pwm_mode(PWM_MODE_MS);
$pi->pwm_clock(DIVISOR);
$pi->pwm_range(RANGE);

# set the servo to centre

$s->pwm(LEFT);

sleep 1;

while ($run){
    for (LEFT .. RIGHT){
        # sweep all the way left to right
        $s->pwm($_);
        select(undef, undef, undef, DELAY);
    }

    sleep 1;

    for (reverse LEFT .. RIGHT){
        # sweep all the way right to left
        $s->pwm($_);
        select(undef, undef, undef, DELAY);
    }

    sleep 1;
}

# set the pin back to INPUT

$s->pwm(LEFT);
$s->mode(INPUT);

