use strict;
use warnings;

use RPi::ADC::ADS;
use Test::More;

my $mod = 'RPi::ADC::ADS';

my %map = (
    4 => [
        33539,
        131,
        3,
    ],
    5 => [
        37635,
        147,
        3,
    ],
    6 => [
        41731,
        163,
        3,
    ],
    7 => [
        45827,
        179,
        3,
    ],
    0 => [ # default
        49923,
        195,
        3,
    ],
    1 => [
        54019,
        211,
        3,
    ],
    2 => [
        58115,
        227,
        3,
    ],
    3 => [
        62211,
        243,
        3,
    ],
);

{ # channel (bits 2-0)

    my $o = $mod->new;

    is $o->bits, 49923, "default bits ok";

    # printf("xxx: %b\n", $o->bits);

    my ($m, $l) = $o->register;
    is $m, 195, "default msb ok";
    is $l, 3, "default lsb ok";

    for (qw(0 1 2 3 4 5 6 7)){
        $o->channel($_);
        is $o->bits, $map{$_}->[0], "$_ bits ok";

        # printf("$_: %b\n", $o->bits);

        my ($m, $l) = $o->register;
        is $m, $map{$_}->[1], "$_ msb ok";
        is $l, $map{$_}->[2], "$_ lsb ok";
    }

    $o->channel(4);
    # printf("0: %b\n", $o->bits);
    is $o->bits, 33539, "0 goes back to original bits ok";
}


{ # bad

    my $o = $mod->new;

    my $ok = eval { $o->channel(9); 1; };

    is $ok, undef, "dies on bad param";
    like $@, qr/channel param requires/, "...error msg ok";
}

done_testing();
