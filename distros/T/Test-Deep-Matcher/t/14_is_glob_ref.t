use strict;
use Test::Tester;
use Test::More;
use Test::Deep;
use Test::Deep::Matcher;
use Symbol;

check_test(
    sub { cmp_deeply(Symbol::gensym, is_glob_ref) },
    {
        actual_ok => 1,
        diag      => '',
    },
    'with glob ref',
);

check_test(
    sub { cmp_deeply('', is_glob_ref) },
    {
        actual_ok => 0,
        diag      => <<__DIAG__,
Checking \$data is glob ref
   got : (NONREF)
expect : GLOB
__DIAG__
    },
    'with non-ref',
);

for my $got (\'', [], +{}, sub {}) {
    my $ref = ref($got);
    check_test(
        sub { cmp_deeply($got, is_glob_ref) },
        {
            actual_ok => 0,
            diag      => <<__DIAG__,
Checking \$data is glob ref
   got : $ref
expect : GLOB
__DIAG__
        },
        "with $ref ref",
    );
}

done_testing;
