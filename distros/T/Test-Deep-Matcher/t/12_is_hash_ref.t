use strict;
use Test::Tester;
use Test::More;
use Test::Deep;
use Test::Deep::Matcher;
use Symbol;

check_test(
    sub { cmp_deeply(+{}, is_hash_ref) },
    {
        actual_ok => 1,
        diag      => '',
    },
    'with hash ref',
);

check_test(
    sub { cmp_deeply('', is_hash_ref) },
    {
        actual_ok => 0,
        diag      => <<__DIAG__,
Checking \$data is hash ref
   got : (NONREF)
expect : HASH
__DIAG__
    },
    'with non-ref',
);

for my $got (\'', [], sub {}, Symbol::gensym) {
    my $ref = ref($got);
    check_test(
        sub { cmp_deeply($got, is_hash_ref) },
        {
            actual_ok => 0,
            diag      => <<__DIAG__,
Checking \$data is hash ref
   got : $ref
expect : HASH
__DIAG__
        },
        "with $ref ref",
    );
}

done_testing;
