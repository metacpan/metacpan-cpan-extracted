use strict;
use warnings;

use RPi::ADC::ADS;
use Test::More;

my $mod = 'RPi::ADC::ADS';

my %map = (
    0 => [
            49923,
            195,
            3,
        ],
    1 => [
            49955,
            195,
            35,
        ],
    2 => [
            49987,
            195,
            67,
        ],
    3 => [
            50019,
            195,
            99,
        ],
    4 => [
            50051,
            195,
            131,
        ],
    5 => [
            50083,
            195,
            163,
        ],
    6 => [
            50115,
            195,
            195,
        ],
    7 => [
            50147,
            195,
            227,
        ],
);

{ # rate (bits 2-0)

    my $o = $mod->new;

    is $o->bits, 49923, "default bits ok";

    # printf("xxx: %b\n", $o->bits);

    my ($m, $l) = $o->register;
    is $m, 195, "default msb ok";
    is $l, 3, "default lsb ok";

    for (qw(0 1 2 3 4 5 6 7)){
        $o->rate($_);
        is $o->bits, $map{$_}->[0], "$_ bits ok";

        # printf("$_: %b\n", $o->bits);

        my ($m, $l) = $o->register;
        is $m, $map{$_}->[1], "$_ msb ok";
        is $l, $map{$_}->[2], "$_ lsb ok";
    }

    $o->rate(0);
    # printf("0: %b\n", $o->bits);
    is $o->bits, 49923, "000 goes back to default bits ok";
}


{ # bad

    my $o = $mod->new;

    my $ok = eval { $o->rate(9); 1; };

    is $ok, undef, "dies on bad param";
    like $@, qr/rate param requires/, "...error msg ok";
}

done_testing();
