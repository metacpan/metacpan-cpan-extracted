use warnings;
use strict;
use feature 'say';

use lib 't/';

use RPiTest;
use RPi::WiringPi;
use Test::More;

rpi_running_test(__FILE__);

my $pi = RPi::WiringPi->new(label => 't/408-sysinfo_pi_model.t', shm_key => 'rpit');

# pi_model() is inherited from RPi::SysInfo. It returns the normalized board
# name from the devicetree model (present on the Pi 0-5), falling back to a
# /proc/cpuinfo Revision-code decode. Assert board-agnostically so this passes
# on any Raspberry Pi, old or new.

my $model = $pi->pi_model;

like $model, qr/Raspberry Pi/, "pi_model() returns a Raspberry Pi board name";

my @lines = split /\n/, $model;
is scalar(@lines), 1, "...and it is a single line";

$pi->cleanup;

rpi_check_pin_status();
#rpi_metadata_clean();

done_testing();
