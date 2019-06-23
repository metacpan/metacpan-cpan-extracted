use warnings;
use strict;

use RPi::WiringPi;
use Test::More;

if (! $ENV{PI_BOARD}){
    plan skip_all => "Not on a Pi board";
}

my $pi = RPi::WiringPi->new;

like $pi->mem_percent, qr/^\d+\.\d+$/, "mem_percent() method return ok";

done_testing();