use warnings;
use strict;
use feature 'say';

use lib 't/';

use RPiTest;
use RPi::WiringPi;
use Test::More;

# plan skip_all => "DISABLED DUE TO RECALIBRATION NEEDED";

if (! $ENV{RPI_STEPPER}){
    plan(skip_all => "RPI_STEPPER environment variable not set");
}

use constant {
    DEBUG => 0
};

rpi_running_test(__FILE__);

my $pi = RPi::WiringPi->new(label => 't/450-stepper.t', shm_key => 'rpit');
my $expander = $pi->expander(0x20);
my $adc = $pi->adc(addr => 0x49);   # ADS1115 #2 (stepper rig; sensors on ch 0/1/2)

my $s = $pi->stepper_motor(
    pins => [0, 1, 2, 3],   # BANK A, pins 0-3 on expander
    expander => $expander,
    delay => 0.0,
    speed => 'full'
);

my ($l, $c, $r) = (2, 1, 0);
my ($high, $low) = (1850, 1650);

# centre

display('centre') if DEBUG;

is $adc->raw($l) < $low, 1, "start: left is low";
is $adc->raw($c) > $high, 1, "start: CENTRE is HIGH";
is $adc->raw($r) < $low, 1, "start: right is low";

# left (from centre)

$s->ccw(90);

is $adc->raw($l) > $high, 1, "C->L: LEFT is HIGH";
is $adc->raw($c) < $low, 1, "C->L: centre is low";
is $adc->raw($r) < $low, 1, "C->L: right is low";
display('left') if DEBUG;

# centre (from left)

$s->cw(90);

is $adc->raw($l) < $low, 1, "L->C: left is low";
is $adc->raw($c) > $high, 1, "L->C: CENTRE is HIGH";
is $adc->raw($r) < $low, 1, "L->C: right is low";
display('centre') if DEBUG;

# right (from centre)

$s->cw(90);

is $adc->raw($l) < $low, 1, "C->R: left is low";
is $adc->raw($c) < $low, 1, "C->R: centre is low";
is $adc->raw($r) > $high, 1, "C->R: RIGHT is HIGH";
display('right') if DEBUG;

# centre (from right)

$s->ccw(90);

is $adc->raw($l) < $low, 1, "R->C: left is low";
is $adc->raw($c) > $high, 1, "R->C: CENTRE is HIGH";
is $adc->raw($r) < $low, 1, "R->C: right is low";
display('centre') if DEBUG;

$expander->cleanup;
$pi->cleanup;

rpi_check_pin_status();
#rpi_metadata_clean();

done_testing();

sub display {
    my ($position) = @_;

    say $position;
    say "L: " . $adc->raw($l);
    say "C: " . $adc->raw($c);
    say "R: " . $adc->raw($r);
    say "\n";
}

