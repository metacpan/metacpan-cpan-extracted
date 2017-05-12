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
    my $v = $obj->raw;

    like $v, qr/^\d+$/, "raw() returns proper integer";
}

done_testing();