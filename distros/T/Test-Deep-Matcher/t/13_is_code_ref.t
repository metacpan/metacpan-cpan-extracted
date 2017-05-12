use strict;
use Test::Tester;
use Test::More;
use Test::Deep;
use Test::Deep::Matcher;
use Symbol;

check_test(
    sub { cmp_deeply(sub {}, is_code_ref) },
    {
        actual_ok => 1,
        diag      => '',
    },
    'with code ref',
);

check_test(
    sub { cmp_deeply('', is_code_ref) },
    {
        actual_ok => 0,
        diag      => <<__DIAG__,
Checking \$data is code ref
   got : (NONREF)
expect : CODE
__DIAG__
    },
    'with non-ref',
);

for my $got (\'', [], +{}, Symbol::gensym) {
    my $ref = ref($got);
    check_test(
        sub { cmp_deeply($got, is_code_ref) },
        {
            actual_ok => 0,
            diag      => <<__DIAG__,
Checking \$data is code ref
   got : $ref
expect : CODE
__DIAG__
        },
        "with $ref ref",
    );
}

done_testing;
