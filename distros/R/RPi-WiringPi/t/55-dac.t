use warnings;
use strict;

use lib 't/';

use RPiTest qw(check_pin_status);
use RPi::WiringPi;
use RPi::Const qw(:all);
use Test::More;
use WiringPi::API qw(:all);

if (! $ENV{RPI_MCP4922}){
    plan skip_all => "RPI_MCP4922 environment variable not set\n";
}

if (! $ENV{RPI_MCP3008}){
    plan skip_all => "RPI_MCP3008 environment variable not set\n";
}

if (! $ENV{PI_BOARD}){
    $ENV{NO_BOARD} = 1;
    plan skip_all => "Not on a Pi board\n";
}

my ($adc_cs_pin, $dac_cs_pin) = (26, 12);

my $adc_dac0_in = 1;
my $adc_dac1_in = 3;

my $pi = RPi::WiringPi->new;

my $dac = $pi->dac(
    model => 'MCP4922',
    channel => 0,
    cs => $dac_cs_pin
);

my $adc = $pi->adc(
    model => 'MCP3008',
    channel => $adc_cs_pin
);

my @output = (
    [0, 2],
    [22, 27],
    [46, 52],
    [70, 76],
    [95, 100],
    [95, 100],
);

{ # dac0
    my $c = 0;

    for (0..4095){
        $dac->set(0, $_);

        if ($_ % 1000 == 0 || $_ == 4095){
            my $r = $adc->percent($adc_dac0_in);

            is 
                $r >= $output[$c]->[0] && $r <= $output[$c]->[1], 
                1,
                "DAC 0 output at $_ ok";

            $c++;
        }
    }
}

{ # dac1
    my $c = 0;

    for (0..4095){
        $dac->set(1, $_);

        if ($_ % 1000 == 0 || $_ == 4095){
            my $r = $adc->percent($adc_dac1_in);
            is 
                $r >= $output[$c]->[0] && $r <= $output[$c]->[1], 
                1,
                "DAC 1 output at $_ ok";

            $c++;
        }
    }
}

$pi->cleanup;

check_pin_status();

done_testing();
