use strict;
use warnings;

use RPi::ADC::ADS;
use Test::More;

my $mod = 'RPi::ADC::ADS';

my %map = (
    0 => [
            49411,
            193,
            3,
        ],
    1 => [
            49923,
            195,
            3,
        ],
    2 => [
            50435,
            197,
            3,
        ],
    3 => [
            50947,
            199,
            3,
        ],
    4 => [
            51459,
            201,
            3,
        ],
    5 => [
            51971,
            203,
            3,
        ],
    6 => [
            52483,
            205,
            3,
        ],
    7 => [
            52995,
            207,
            3,
        ],
);

{ # gain (bits 2-0)

    my $o = $mod->new;

    is $o->bits, 49923, "default bits ok";

    # printf("xxx: %b\n", $o->bits);

    my ($m, $l) = $o->register;
    is $m, 195, "default msb ok";
    is $l, 3, "default lsb ok";

    for (qw(0 1 2 3 4 5 6 7)){
        $o->gain($_);
        is $o->bits, $map{$_}->[0], "$_ bits ok";

        # printf("$_: %b\n", $o->bits);

        my ($m, $l) = $o->register;
        is $m, $map{$_}->[1], "$_ msb ok";
        is $l, $map{$_}->[2], "$_ lsb ok";

    }

    $o->gain(0);
    # printf("0: %b\n", $o->bits);
    is $o->bits, 49411, "0 goes back to unset bits ok";
}

done_testing();
exit;
{ # bad

    my $o = $mod->new;

    my $ok = eval { $o->gain(8); 1; };

    is $ok, undef, "dies on bad param";
    like $@, qr/gain param requires/, "...error msg ok";
}

done_testing();
