use warnings;
use strict;

use RPi::WiringPi;

use Test::More;

if (! $ENV{PI_BOARD}){
    plan skip_all => "Not on a Pi board";
}

my $pi = RPi::WiringPi->new;

like $pi->cpu_percent, qr/^\d+\.\d+$/, "cpu_percent() method return ok";

done_testing();