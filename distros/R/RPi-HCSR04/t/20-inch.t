use strict;
use warnings;
use Test::More;

if (! $ENV{RPI_BOARD}){
    plan skip_all => "not a Pi board: RPI_BOARD not set";
    exit;
}

if (! $ENV{RPI_HCSR04}){
    plan skip_all => "RPI_HCSR04 env var not set, skipping";
    exit;
}

use RPi::HCSR04;

my $mod = 'RPi::HCSR04';

{
    my $o = $mod->new(23, 24);
    my $i = $o->inch;
    like $i, qr/^\d+\.\d+$/, "float is returned";
}

done_testing();
