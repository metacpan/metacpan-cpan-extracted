use warnings;
use strict;
use feature 'say';

use lib 't/';

use RPiTest;
use RPi::WiringPi;
use Test::More;

rpi_running_test(__FILE__);

my $pi = RPi::WiringPi->new(label => 't/407-sysinfo_pi_details.t', shm_key => 'rpit');

# pi_details() concatenates the devicetree model, os-release, uname and the tail
# of /proc/cpuinfo. Assert on board-agnostic invariants present on every Pi
# (modern /proc/cpuinfo no longer carries a "BCM2835"-style Hardware line).

like $pi->pi_details, qr|Raspberry Pi|, "method includes the model name";
like $pi->pi_details, qr/Revision\s*:/, "method includes the cpuinfo Revision";
like $pi->pi_details, qr/Serial\s*:/, "method includes the cpuinfo Serial";
like $pi->pi_details, qr/Model\s*:/, "method includes the cpuinfo Model";

$pi->cleanup;

rpi_check_pin_status();
#rpi_metadata_clean();

done_testing();
