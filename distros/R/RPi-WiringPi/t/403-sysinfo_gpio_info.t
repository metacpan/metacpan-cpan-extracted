use warnings;
use strict;
use feature 'say';

use lib 't/';

use RPiTest;
use RPi::WiringPi;
use Test::More;

rpi_running_test(__FILE__);

my $pi = RPi::WiringPi->new(label => 't/403-sysinfo_gpio_info.t', shm_key => 'rpit');

# gpio_info() is proxied to RPi::SysInfo, which drives pinctrl on current Pi OS
# (raspi-gpio was removed). Each line looks like "20: no pd | -- // GPIO20 = none".

my $all = $pi->gpio_info();
my @all_lines = split /\n/, $all;
like $all, qr/GPIO\d+ = /, "with no pins param, output is in the expected format";
like $all, qr/GPIO2 = /, "with no pins param, a known pin (2) is present";
cmp_ok scalar(@all_lines), '>=', 28, "with no pins param, the full set of pins is returned";

my $one = $pi->gpio_info([20]);
my @one_lines = split /\n/, $one;
like $one, qr/GPIO20 = /, "with 20 as a param, method return ok";
is scalar(@one_lines), 1, "...and a single pin returns exactly one line";

my $four_ret = $pi->gpio_info([2, 4, 6, 8]);
my @four_lines = split /\n/, $four_ret;

like $four_ret, qr/GPIO2 = /, "with 2,4,6,8 as a param, pin 2 method ok";
like $four_ret, qr/GPIO4 = /, "with 2,4,6,8 as a param, pin 4 method ok";
like $four_ret, qr/GPIO6 = /, "with 2,4,6,8 as a param, pin 6 method ok";
like $four_ret, qr/GPIO8 = /, "with 2,4,6,8 as a param, pin 8 method ok";
unlike $four_ret, qr/GPIO9 = /, "...and pin 9 is excluded";
is scalar(@four_lines), 4, "...and exactly four lines are returned";

$pi->cleanup;

rpi_check_pin_status();
#rpi_metadata_clean();

done_testing();
