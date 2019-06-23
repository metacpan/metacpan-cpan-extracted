use warnings;
use strict;
use feature 'say';

use RPi::SysInfo qw(:all);
use Test::More;

if (! $ENV{PI_BOARD}){
    plan skip_all => "Not on a Pi board";
}

my $sys = RPi::SysInfo->new;

like $sys->network_info, qr/inet/, "method includes data ok";

like network_info(), qr/inet/, "function includes data ok";

done_testing();