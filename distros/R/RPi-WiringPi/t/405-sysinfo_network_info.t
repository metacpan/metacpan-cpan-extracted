use warnings;
use strict;
use feature 'say';

use lib 't/';

use RPiTest;
use RPi::WiringPi;
use Test::More;

rpi_running_test(__FILE__);

my $pi = RPi::WiringPi->new(label => 't/405-sysinfo_network_info.t', shm_key => 'rpit');
like $pi->network_info, qr/inet/, "method includes data ok";

$pi->cleanup;

rpi_check_pin_status();
#rpi_metadata_clean();

done_testing();
