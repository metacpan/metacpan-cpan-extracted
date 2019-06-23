use warnings;
use strict;
use feature 'say';

use RPi::WiringPi;
use Test::More;

if (! $ENV{PI_BOARD}){
    plan skip_all => "Not on a Pi board";
}

my $pi = RPi::WiringPi->new;

like $pi->network_info, qr/inet/, "method includes data ok";

done_testing();