use warnings;
use strict;

use lib 't/';

use RPiTest;

use RPi::WiringPi;
use RPi::Const qw(:all);
use Test::More;

if (! $ENV{RPI_BMP}){
    plan skip_all => "RPI_BMP environment variable not set\n";
}

use constant {
    BMP_BASE => 100,
};

rpi_running_test(__FILE__);

my $pi = RPi::WiringPi->new(label => 't/340-bmp.t', shm_key => 'rpit');
my $bmp = $pi->bmp(BMP_BASE);

for (1..25){
    is $bmp->temp('c') < 35, 1, "temp celcius within range high, pass $_";
    is $bmp->temp('c') > 13, 1, "temp celcius within range low, pass $_";

    is $bmp->temp('c') < $bmp->temp, 1, "temp c is less than f, pass $_";
    is $bmp->temp > $bmp->temp('c'), 1, "temp f is greater than c, pass $_";

    is $bmp->pressure > 80, 1, "pressure seems legit (low), pass $_";
    is $bmp->pressure < 110, 1, "pressure seems legit (high), pass $_";

}

$pi->cleanup;

rpi_check_pin_status();
#rpi_metadata_clean();

done_testing();
