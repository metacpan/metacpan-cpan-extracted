use strict;
use Test::Tester;
use Test::More;
use Test::Deep;
use Test::Deep::Matcher;

my $got = +{
    value   => '',
    string  => 'string',
    number  => 123.456,
    integer => 10,
};

check_test(
    sub {
        cmp_deeply($got, +{
            value   => is_value,
            string  => is_string,
            number  => is_number,
            integer => is_integer,
        });
    },
    {
        actual_ok => 1,
        diag      => '',
    },
    'with complex struct with primitives',
);

done_testing;
