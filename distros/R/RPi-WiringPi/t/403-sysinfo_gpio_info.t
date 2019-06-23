use warnings;
use strict;
use feature 'say';

use RPi::WiringPi;
use Test::More;

if (! $ENV{PI_BOARD}){
    plan skip_all => "Not on a Pi board";
}

my $pi = RPi::WiringPi->new;

like $pi->gpio_info(), qr/GPIO 53:/, "with no pins param, method return is ok";
like $pi->gpio_info([20]), qr/^GPIO 20:/, "with 20 as a param, method return ok";

my $four_ret = $pi->gpio_info([2, 4, 6, 8]);

like $four_ret, qr/GPIO 2:/, "with 2,4,6,8 as a param, pin 2 method ok";
like $four_ret, qr/GPIO 4:/, "with 2,4,6,8 as a param, pin 4 method ok";
like $four_ret, qr/GPIO 6:/, "with 2,4,6,8 as a param, pin 6 method ok";
like $four_ret, qr/GPIO 8:/, "with 2,4,6,8 as a param, pin 8 method ok";
unlike $four_ret, qr/GPIO 9:/, "...and pin 9 is excluded";

done_testing();
