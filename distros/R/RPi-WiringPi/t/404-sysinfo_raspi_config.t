use warnings;
use strict;
use feature 'say';

use lib 't/';

use RPiTest;
use RPi::WiringPi;
use Test::More;

rpi_running_test(__FILE__);

my $pi = RPi::WiringPi->new(label => 't/404-sysinfo_raspi_config.t', shm_key => 'rpit');

like $pi->raspi_config, qr/core_freq/, "method includes vcgencmd data ok";

# config.txt is resolved by RPi::SysInfo (/boot/firmware/config.txt on Bookworm+,
# /boot/config.txt on older). Every Pi config.txt carries at least one dtparam=
# or dtoverlay= directive, and comment lines are stripped.

like
    $pi->raspi_config,
    qr/^dt(?:param|overlay)=/m,
    "...and config.txt directives are included";

unlike $pi->raspi_config, qr/^\s*#/m, "...and config.txt comment lines are stripped";

$pi->cleanup;

rpi_check_pin_status();
#rpi_metadata_clean();

done_testing();
