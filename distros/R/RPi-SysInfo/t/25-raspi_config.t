use warnings;
use strict;
use feature 'say';

use RPi::SysInfo qw(:all);
use Test::More;

if (! $ENV{PI_BOARD}){
    plan skip_all => "Not on a Pi board";
}

my $sys = RPi::SysInfo->new;

like $sys->raspi_config, qr/core_freq/, "method includes data ok";

like raspi_config, qr/core_freq/, "function includes data ok";

like
    raspi_config,
    qr/dtoverlay=pi3-disable-bt-overlay/,
    "...and custom changes are included";

done_testing();