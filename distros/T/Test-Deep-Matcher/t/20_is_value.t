use strict;
use Test::Tester;
use Test::More;
use Test::Deep;
use Test::Deep::Matcher;

for my $got ('str', '', 100, 50.123, 0, -3) {
    check_test(
        sub { cmp_deeply($got, is_value) },
        {
            actual_ok => 1,
            diag      => '',
        },
        "with '$got' value",
    );
}

check_test(
    sub { cmp_deeply(undef, is_value) },
    {
        actual_ok => 0,
        diag      => <<__DIAG__,
Checking \$data is value
   got : (undef)
expect : (is value)
__DIAG__
    },
    'with undef',
);

done_testing;
