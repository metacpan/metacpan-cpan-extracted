use warnings;
use strict;

use lib 't/';

use RPiTest;
use RPi::WiringPi;
use Test::More;

rpi_running_test(__FILE__);

my $pi = RPi::WiringPi->new(label => 't/401-sysinfo_mem_percent.t', shm_key => 'rpit');
like $pi->mem_percent, qr/^\d+\.\d+$/, "mem_percent() method return ok";

$pi->cleanup;

rpi_check_pin_status();
#rpi_metadata_clean();

done_testing();
