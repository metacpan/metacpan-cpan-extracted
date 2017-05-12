#!perl

use Test::More;
use Test::Deep;
use Test::Lib;
use Moo::Role ();

{
    package C;
    use R1;
}

cmp_deeply(
    C->_tags,
    {
        T1_1 => {
            r1_1 => 'r1_1.t1_1',
            r1_2 => 'r1_2.t1_1',
        },
        T1_2 => {
            r1_1 => 'r1_1.t1_2',

        },
    },
    'initial tags',
);

Moo::Role->apply_roles_to_package( 'C', 'R2' );

cmp_deeply(
    C->_tags,
    {
        T1_1 => {
            r1_1 => 'r1_1.t1_1',
            r1_2 => 'r1_2.t1_1',
        },
        T1_2 => {
            r1_1 => 'r1_1.t1_2',

        },
        T2_1 => {
            r2_1 => 'r2_1.t2_1',
            r2_2 => 'r2_2.t2_1',
        },
        T2_2 => {
            r2_1 => 'r2_1.t2_2',
        },

    },
    'initial tags',
);

done_testing;
