use warnings;
use strict;
use feature 'say';

use RPi::WiringPi;
use Test::More;

if (! $ENV{PI_BOARD}){
    plan skip_all => "Not on a Pi board";
}

my $pi = RPi::WiringPi->new;

like $pi->file_system, qr|/dev/root|, "method includes root ok";

like $pi->file_system, qr|/var/swap|, "method includes swap ok";

done_testing();