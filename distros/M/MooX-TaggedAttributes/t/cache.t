#!perl

use Test2::V0;
use Test::Lib;
use Moo::Role ();

{
    package C;

    use Moo;
    use R1;
}

is(
    C->_tags,
    hash {
        field T1_1 => hash {
            field r1_1 => 'r1_1.t1_1';
            field r1_2 => 'r1_2.t1_1';
        };
        field T1_2 => hash {
            field r1_1 => 'r1_1.t1_2';

        };
    },
    'initial tags',
);

Moo::Role->apply_roles_to_package( 'C', 'R2' );

is(
    C->_tags,
    hash {
        field T1_1 => hash {
            field r1_1 => 'r1_1.t1_1';
            field r1_2 => 'r1_2.t1_1';
        };
        field T1_2 => hash {
            field r1_1 => 'r1_1.t1_2';

        };
        field T2_1 => hash {
            field r2_1 => 'r2_1.t2_1';
            field r2_2 => 'r2_2.t2_1';
        };
        field T2_2 => hash {
            field r2_1 => 'r2_1.t2_2';
        };
    },
    'initial tags',
);

done_testing;
