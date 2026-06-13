use warnings;
use strict;

use lib 't/';

use RPiTest;
use RPi::WiringPi;
use RPi::Const qw(:all);
use Test::More;

if (! $ENV{RPI_DIGIPOT}){
    plan skip_all => "RPI_DIGIPOT environment variable not set\n";
}

if (! $ENV{RPI_ADC}){
    plan skip_all => "RPI_ADC environment variable not set\n";

}

use constant {
    DPOT_CS => 13,
    DPOT_CH => 0,
    ADC_CH => 1,
};

rpi_running_test(__FILE__);

my $pi = RPi::WiringPi->new(label => 't/345-dpot.t', shm_key => 'rpit');
# Belt-and-braces: if an assertion or library call dies mid-run, release the
# pins/registration this object holds (the library END reap is best-effort)

END { $pi->cleanup if $pi && ! $pi->{clean}; }


my $adc = $pi->adc(addr => 0x48);   # ADS1115 #1 (dpot wiper on ch 1)
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

rpi_check_pin_status();
#rpi_metadata_clean();

done_testing();
