use warnings;
use strict;

use lib 't/';

use RPiTest;
use Test::More;
use WiringPi::API qw(:perl);

rpi_running_test(__FILE__);

setup_gpio();

rpi_check_pin_status();
#rpi_metadata_clean();

done_testing();
