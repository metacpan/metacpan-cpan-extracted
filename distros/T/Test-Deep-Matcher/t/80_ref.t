use strict;
use Test::Tester;
use Test::More;
use Test::Deep;
use Test::Deep::Matcher;
use Symbol;

my $got = +{
    scalar_ref => \'',
    array_ref  => [],
    hash_ref   => +{},
    code_ref   => sub {},
    glob_ref   => Symbol::gensym,
};

check_test(
    sub {
        cmp_deeply($got, +{
            scalar_ref => is_scalar_ref,
            array_ref  => is_array_ref,
            hash_ref   => is_hash_ref,
            code_ref   => is_code_ref,
            glob_ref   => is_glob_ref,
        });
    },
    {
        actual_ok => 1,
        diag      => '',
    },
    'with complex struct with reference',
);

done_testing;
