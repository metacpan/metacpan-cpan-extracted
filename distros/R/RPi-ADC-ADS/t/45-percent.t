use strict;
use warnings;

use RPi::ADC::ADS;
use Test::More;

if (! $ENV{PI_TEST}){
    plan skip_all => "PI_TEST env var not set";
    exit;
}

my $mod = 'RPi::ADC::ADS';

{ # default

    my $obj = $mod->new;
    my $p = $obj->percent;

    like $p, qr/^\d{1,3}\.\d+$/, "percent() returns proper float";
}

done_testing();