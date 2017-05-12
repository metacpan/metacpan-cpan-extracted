use strict;
use Test::Tester;
use Test::More;
use Test::Deep;
use Test::Deep::Matcher;

for my $got ('str', 100, 50.123, 0, -3) {
    check_test(
        sub { cmp_deeply($got, is_string) },
        {
            actual_ok => 1,
            diag      => '',
        },
        "with '$got' value",
    );
}

check_test(
    sub { cmp_deeply('', is_string) },
    {
        actual_ok => 0,
        diag      => <<__DIAG__,
Checking \$data is string
   got : \
expect : (is string)
__DIAG__
    },
    'with empty string',
);

check_test(
    sub { cmp_deeply(undef, is_string) },
    {
        actual_ok => 0,
        diag      => <<__DIAG__,
Checking \$data is string
   got : (undef)
expect : (is string)
__DIAG__
    },
    'with undef',
);

done_testing;
