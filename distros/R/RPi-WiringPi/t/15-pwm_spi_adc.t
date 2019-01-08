use strict;
use warnings;

use lib 't/';

use RPiTest qw(check_pin_status);
use RPi::WiringPi;
use Test::More;

my $mod = 'RPi::WiringPi';

if ($> == 0){
    $ENV{PI_BOARD} = 1;
    $ENV{RPI_ADC} = 1;
}

if (! $ENV{RPI_ADC}){
    plan skip_all => "RPI_ADC environment variable not set\n";
}

if (! $ENV{PI_BOARD}){
    $ENV{NO_BOARD} = 1;
    plan skip_all => "Not on a Pi board\n";
}

if ($> != 0){
    print "enforcing sudo for PWM tests...\n";
    system('sudo', 'perl', $0);
    exit;
}

my $pi = $mod->new;
my $adc = $pi->adc;

my $adc_in = 0;

if (! $ENV{NO_BOARD}) {

    my %output = (
        100     =>  [8..13],
        200     =>  [18..22],
        300     =>  [27..31],
        400     =>  [36..42],
        500     =>  [46..50],
        600     =>  [58..62],
        700     =>  [67..70],
        800     =>  [75..79],
        900     =>  [86..89],
        1000    =>  [96..100]
    );

    my $pin = $pi->pin(18);
    $pin->mode(2);
    is $pin->mode, 2, "pin mode set to PWM ok, and we can read it";

    for my $pwm (0..400){
        next if $pwm == 0;
        next if $pwm % 100 != 0;
        $pin->pwm($pwm);
        my $res = $adc->percent($adc_in);

        is $res > $output{$pwm}->[0], 1, "$pwm: pwm $res in range of lower end ok";
        is $output{$pwm}->[-1] > $res, 1, "$pwm: pwm $res in range of upper end ok";
    }

    $pi->cleanup;

    select(undef, undef, undef, 0.02);
    check_pin_status();
}

$pi->cleanup;

done_testing();
