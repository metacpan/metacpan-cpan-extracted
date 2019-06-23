use warnings;
use strict;

use RPi::WiringPi;
use Test::More;

if (! $ENV{PI_BOARD}){
    plan skip_all => "Not on a Pi board";
}

my $pi = RPi::WiringPi->new;

like $pi->core_temp, qr/^\d+\.\d+$/, "core_temp() method return ok";

my $tC = $pi->core_temp();
my $tF = $pi->core_temp('f');

is $tF > $tC, 1, "f and c temps ok";

done_testing();