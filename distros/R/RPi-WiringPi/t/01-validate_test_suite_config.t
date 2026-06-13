use warnings;
use strict;

use lib 't/';

use RPiTest;
use Test::More;

rpi_running_test(__FILE__);

rpi_reset();

rpi_check_pin_status();

done_testing();
