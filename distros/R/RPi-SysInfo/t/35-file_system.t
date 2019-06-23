use warnings;
use strict;
use feature 'say';

use RPi::SysInfo qw(:all);
use Test::More;

if (! $ENV{PI_BOARD}){
    plan skip_all => "Not on a Pi board";
}

my $sys = RPi::SysInfo->new;

like $sys->file_system, qr|/dev/root|, "method includes root ok";
like file_system(), qr|/dev/root|, "function includes root ok";

like $sys->file_system, qr|/var/swap|, "method includes swap ok";
like file_system(), qr|/var/swap|, "function includes swap ok";

done_testing();