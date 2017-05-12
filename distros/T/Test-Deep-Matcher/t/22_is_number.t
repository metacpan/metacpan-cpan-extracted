use strict;
use Test::Tester;
use Test::More;
use Test::Deep;
use Test::Deep::Matcher;

for my $got (100, 50.123, 0, -3) {
    check_test(
        sub { cmp_deeply($got, is_number) },
        {
            actual_ok => 1,
            diag      => '',
        },
        "with '$got' number value",
    );
}

for my $got ('str', '') {
    check_test(
        sub { cmp_deeply($got, is_number) },
        {
            actual_ok => 0,
            diag      => <<__DIAG__,
Checking \$data is number
   got : $got
expect : (is number)
__DIAG__
        },
        'with string',
    );
}

check_test(
    sub { cmp_deeply(undef, is_number) },
    {
        actual_ok => 0,
        diag      => <<__DIAG__,
Checking \$data is number
   got : (undef)
expect : (is number)
__DIAG__
    },
    'with undef',
);

done_testing;
