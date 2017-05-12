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
            49931,
            195,
            11,
        ],
);

{ # polarity (bits 2-0)

    my $o = $mod->new;

    is $o->bits, 49923, "default bits ok";

    my ($m, $l) = $o->register;
    is $m, 195, "default msb ok";
    is $l, 3, "default lsb ok";

    for (qw(0 1)){
        $o->polarity($_);
        is $o->bits, $map{$_}->[0], "$_ bits ok";

        # printf("$_: %b\n", $o->bits);

        my ($m, $l) = $o->register;
        is $m, $map{$_}->[1], "$_ msb ok";
        is $l, $map{$_}->[2], "$_ lsb ok";
    }

    # $o->polarity(0);
    # printf("0: %b\n", $o->bits);
}

{ # bad

    my $o = $mod->new;

    my $ok = eval { $o->polarity('111'); 1; };

    is $ok, undef, "dies on bad param";
    like $@, qr/polarity param requires/, "...error msg ok";
}

done_testing();
