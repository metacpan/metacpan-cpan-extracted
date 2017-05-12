use strict;
use Test::Tester;
use Test::More;
use Test::Deep;
use Test::Deep::Matcher;
use Symbol;

check_test(
    sub { cmp_deeply(\'', is_scalar_ref) },
    {
        actual_ok => 1,
        diag      => '',
    },
    'with scalar ref',
);

check_test(
    sub { cmp_deeply('', is_scalar_ref) },
    {
        actual_ok => 0,
        diag      => <<__DIAG__,
Checking \$data is scalar ref
   got : (NONREF)
expect : SCALAR
__DIAG__
    },
    'with non-ref',
);

for my $got ([], +{}, sub {}, Symbol::gensym) {
    my $ref = ref($got);
    check_test(
        sub { cmp_deeply($got, is_scalar_ref) },
        {
            actual_ok => 0,
            diag      => <<__DIAG__,
Checking \$data is scalar ref
   got : $ref
expect : SCALAR
__DIAG__
        },
        "with $ref ref",
    );
}

done_testing;
