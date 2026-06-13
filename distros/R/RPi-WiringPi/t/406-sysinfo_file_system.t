use warnings;
use strict;
use feature 'say';

use lib 't/';

use RPiTest;
use RPi::WiringPi;
use Test::More;

rpi_running_test(__FILE__);

my $pi = RPi::WiringPi->new(label => 't/406-sysinfo_file_system.t', shm_key => 'rpit');

# file_system() returns `df` output followed by /proc/swaps. Assert on the
# stable structure rather than specific device names (root may be on SD, USB or
# NVMe; swap may be a zram device or a swapfile).

like $pi->file_system, qr/Filesystem .* Mounted on/, "method includes the df header";

like
    $pi->file_system,
    qr{^\S+ \s+ \d+ \s+ \d+ \s+ \d+ \s+ \d+% \s+ /\s*$}xm,
    "method includes the root (/) mount";

like $pi->file_system, qr/Filename\s+Type\s+Size/, "method includes the swap (/proc/swaps) header";

$pi->cleanup;

rpi_check_pin_status();
#rpi_metadata_clean();

done_testing();
