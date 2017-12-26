#!/usr/bin/perl
use strict;
use warnings;

use lib 't/data';

BEGIN {
    use Mock::Sub;
    use Test::More;
    use_ok('One');
};

{# return params

    my $mock = Mock::Sub->new;
    my $foo = $mock->mock('One::foo');

    my $scalar = One::foo(10);
    is $scalar, 10, "param is returned in scalar context";

    $scalar = One::foo(5, 10);
    is $scalar, 5, "first param is returned in scalar context if list sent in";

    my @array = One::foo(1, 2, 3);

    is @array, $foo->called_with, "number returned params are correct";

    is ref \@array, 'ARRAY', "array of params returned in list context";

    for(0..2){
        is $array[$_], $_ + 1, "returned param $_ is correct";
    }

    $foo->return_value(99);
    $scalar = One::foo(100);
    is $scalar, 99, "if return value is set, we return it, not params";
}

done_testing();
