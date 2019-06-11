use strict;
use warnings;
use Test::More;

use Sub::Data::Recursive;

{
    my $hash = +{
        bar => 1,
    };

    Sub::Data::Recursive->massive_invoke(
        sub {
            is $_[1], 'HASH', 'context is hash';
            is ref($_[2]), 'ARRAY', 'keys';
            is $_[2][0], 'bar', 'array key';

            $_[0]++;
        },
        $hash,
    );

    my $expect = +{
        bar => 2,
    };

    is_deeply $hash, $expect, 'hash context';
}

{
    my $array = [
        1,
        2,
    ];

    Sub::Data::Recursive->massive_invoke(
        sub {
            is $_[1], 'ARRAY', 'context is array';
            is $_[2], undef;

            $_[0]++;
        },
        $array,
    );

    my $expect = [2, 3];

    is_deeply $array, $expect, 'array context';
}

done_testing;
