use strict;
use warnings;
use Test::More;

use_ok 'Sub::Rate';

my $res = q[];

my $func = do {
    my $sub = Sub::Rate->new;
    $sub->add( 50, sub {
        my $r = $_[0] * 1;
        $res .= $r;
        $r;
    });

    $sub->add( 50, sub {
        my $r = $_[0] * 2;
        $res .= $r;
        $r;
    });

    $sub->generate;
};

my $res2 = q[];
for my $i (1 .. 100) {
    my $r = $func->($i);

    ok $r == $i || $r == $i*2, 'res ok';

    $res2 .= $r;
}

is $res, $res2, 'output same ok';

done_testing;
