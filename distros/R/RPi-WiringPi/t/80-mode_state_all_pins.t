use warnings;
use strict;

use lib 't/';

use RPiTest qw(check_pin_status);
use Test::More;
use WiringPi::API qw(:perl);

setup_gpio();

if (! $ENV{PI_BOARD}){
    warn "\n*** PI_BOARD is not set! ***\n";
    $ENV{NO_BOARD} = 1;
    plan skip_all => "not on a pi board\n";
}

check_pin_status();
done_testing();
