use strict;
use warnings;

use lib 't/';

use RPiTest;
use Test::More;

rpi_running_test(__FILE__);

my $pi = RPi::WiringPi->new(label => 't/02-shm_key.t', shm_key => 'rpit');
is $pi->meta_key, 1473559184, "meta key successfully accepted in object instantiation";

is(RPi::WiringPi->meta_key_check('rpit'), 1, "'rpit' shm segment exists");
is(RPi::WiringPi->meta_key_check('blah'), 0, "'blah' shm segment doesn't exist");

$pi->cleanup;

#rpi_check_pin_status();
#rpi_metadata_clean();

done_testing();

