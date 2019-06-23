use warnings;
use strict;

use lib 't/';

use RPiTest qw(check_pin_status);

use RPi::WiringPi;
use RPi::Const qw(:all);
use Test::More;

if (! $ENV{RPI_DIGIPOT}){
    plan skip_all => "RPI_DIGIPOT environment variable not set\n";
}

if (! $ENV{RPI_ADC}){
    plan skip_all => "RPI_ADC environment variable not set\n";

}
if (! $ENV{PI_BOARD}){
    $ENV{NO_BOARD} = 1;
    plan skip_all => "Not on a Pi board\n";
}

use constant {
    DPOT_CS => 13,
    DPOT_CH => 0,
    ADC_CH => 1,
};

my $pi = RPi::WiringPi->new;

my $adc = $pi->adc;
my $pot = $pi->dpot(DPOT_CS, DPOT_CH);

my @values = (
    [0, 1],
    [18, 20],
    [38, 40],
    [57, 60],
    [76, 79],
    [96, 98],
    [98, 100],
);

my $count = 0;

for (0..255){

    if ($_ % 50 == 0 || $_ == 255){
        
        $pot->set($_);
        my $val = $adc->percent(ADC_CH);
        
        is
            $val >= $values[$count]->[0] && $val <= $values[$count]->[1],
            1,
            "POT output at $_ tap ok";
        
        $count++;
    }
}

$pi->cleanup;

check_pin_status();

done_testing();
