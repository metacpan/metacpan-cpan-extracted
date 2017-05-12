use strict;
use Test::Tester;
use Test::More;
use Test::Deep;
use Test::Deep::Matcher;
use Symbol;

check_test(
    sub { cmp_deeply([], is_array_ref) },
    {
        actual_ok => 1,
        diag      => '',
    },
    'with array ref',
);

check_test(
    sub { cmp_deeply('', is_array_ref) },
    {
        actual_ok => 0,
        diag      => <<__DIAG__,
Checking \$data is array ref
   got : (NONREF)
expect : ARRAY
__DIAG__
    },
    'with non-ref',
);

for my $got (\'', +{}, sub {}, Symbol::gensym) {
    my $ref = ref($got);
    check_test(
        sub { cmp_deeply($got, is_array_ref) },
        {
            actual_ok => 0,
            diag      => <<__DIAG__,
Checking \$data is array ref
   got : $ref
expect : ARRAY
__DIAG__
        },
        "with $ref ref",
    );
}

done_testing;
