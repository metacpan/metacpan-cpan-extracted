use warnings;
use strict;
use feature 'say';

use RPi::SysInfo qw(:all);
use Test::More;

if (! $ENV{PI_BOARD}){
    plan skip_all => "Not on a Pi board";
}

my $sys = RPi::SysInfo->new;

like $sys->pi_details, qr|Raspberry Pi|, "method includes data ok";
like pi_details(), qr|Raspberry Pi|, "function includes data ok";

like $sys->pi_details, qr|BCM2835|, "method includes data ok";
like pi_details(), qr|BCM2835|, "function includes data ok";

done_testing();