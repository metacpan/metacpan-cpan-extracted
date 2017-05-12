use strict;
use Test::Tester;
use Test::More;
use Test::Deep;
use Test::Deep::Matcher;

for my $got (100, 0, -3) {
    check_test(
        sub { cmp_deeply($got, is_integer) },
        {
            actual_ok => 1,
            diag      => '',
        },
        "with '$got' integer",
    );
}

for my $got ('str', '', 50.123) {
    check_test(
        sub { cmp_deeply($got, is_integer) },
        {
            actual_ok => 0,
            diag      => <<__DIAG__,
Checking \$data is integer
   got : $got
expect : (is integer)
__DIAG__
        },
        "with '$got' not integer value",
    );
}

check_test(
    sub { cmp_deeply(undef, is_integer) },
    {
        actual_ok => 0,
        diag      => <<__DIAG__,
Checking \$data is integer
   got : (undef)
expect : (is integer)
__DIAG__
    },
    'with undef',
);

done_testing;
