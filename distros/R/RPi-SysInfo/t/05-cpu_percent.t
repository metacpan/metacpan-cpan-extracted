use warnings;
use strict;

use RPi::SysInfo qw(:all);
use Test::More;

if (! $ENV{PI_BOARD}){
    plan skip_all => "Not on a Pi board";
}

my $sys = RPi::SysInfo->new;

is ref $sys, 'RPi::SysInfo', "object is of proper class";

like $sys->cpu_percent, qr/^\d+\.\d+$/, "cpu_percent() method return ok";

sleep 1;

like cpu_percent, qr/^\d+\.\d+$/, "cpu_percent() function return ok";

done_testing();