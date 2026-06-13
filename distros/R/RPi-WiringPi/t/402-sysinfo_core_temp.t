use warnings;
use strict;

use lib 't/';

use RPiTest;
use RPi::WiringPi;
use Test::More;

rpi_running_test(__FILE__);

my $pi = RPi::WiringPi->new(label => 't/402-sysinfo_core_temp.t', shm_key => 'rpit');

like $pi->core_temp, qr/^\d+\.\d+$/, "core_temp() method return ok";

my $tC = $pi->core_temp();
my $tF = $pi->core_temp('f');

is $tF > $tC, 1, "f and c temps ok";

$pi->cleanup;

rpi_check_pin_status();
#rpi_metadata_clean();

done_testing();
