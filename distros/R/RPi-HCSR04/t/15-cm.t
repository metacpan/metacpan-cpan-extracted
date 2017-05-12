use strict;
use warnings;
use Test::More;

if (! $ENV{PI_BOARD}){
    plan skip_all => "not a Pi board: PI_BOARD not set";
    exit;
}

use RPi::HCSR04;

my $mod = 'RPi::HCSR04';

{
    my $o = $mod->new(23, 24);
    my $cm = $o->cm;
    like $cm, qr/^\d+\.\d+$/, "float is returned";
}

done_testing();
