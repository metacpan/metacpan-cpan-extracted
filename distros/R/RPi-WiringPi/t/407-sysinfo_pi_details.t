use warnings;
use strict;
use feature 'say';

use RPi::WiringPi;
use Test::More;

if (! $ENV{PI_BOARD}){
    plan skip_all => "Not on a Pi board";
}

my $pi = RPi::WiringPi->new;

like $pi->pi_details, qr|Raspberry Pi|, "method includes data ok";

like $pi->pi_details, qr|BCM2835|, "method includes data ok";

done_testing();