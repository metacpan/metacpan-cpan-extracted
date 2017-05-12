#!perl

use Test::More;
use Test::Lib;
use My::Test;

my $map = {
    R1  => 'T1',
    R2  => 'T2',
    R3  => 'wR1',
    T12 => 'T1,T2',
};

{
    package B1;

    use Moo;
    use T1;

    has b1_1 => (
        is      => 'rw',
        default => 'b1_1.v',
        T1_1    => 'b1_1.t1_1',
    );
}

check_class(
    'B1',
    {
        b1_1 => 'b1_1.v',
    },
    {
        T1_1 => {
            b1_1 => 'b1_1.t1_1',
        },
    },
    $map, 'T1',
);

{
    package B2;

    use Moo;
    use T2;

    has b2_1 => (
        is      => 'rw',
        default => 'b2_1.v',
        T2_1    => 'b2_1.t2_1',
    );

}

check_class(
    'B2',
    {
        b2_1 => 'b2_1.v',
    },
    {
        T2_1 => {
            b2_1 => 'b2_1.t2_1',
        },
    },
    $map, 'T2'
);

{
    package B3;

    use Moo;
    use T2;
    use T1;

    has b3_1 => (
        is      => 'rw',
        default => 'b3_1.v',
        T1_1    => 'b3_1.t1_1',
        T2_1    => 'b3_1.t2_1',
    );

}

check_class(
    'B3',
    {
        b3_1 => 'b3_1.v',
    },
    {
        T1_1 => {
            b3_1 => 'b3_1.t1_1',
        },
        T2_1 => {
            b3_1 => 'b3_1.t2_1',
        },
    },
    $map, 'T1,T2'
);

{
    package B4;

    use Moo;
    use T12;

    has b4_1 => (
        is      => 'rw',
        default => 'b4_1.v',
        T1_1    => 'b4_1.t1_1',
        T2_1    => 'b4_1.t2_1',
    );

}

check_class(
    'B4',
    {
        b4_1  => 'b4_1.v',
        t12_1 => 't12_1.v',
    },
    {
        T1_1 => {
            b4_1 => 'b4_1.t1_1',
        },
        T2_1 => {
            b4_1 => 'b4_1.t2_1',
        },
    },
    $map, 'T12'
);


{
    package C1;

    use Moo;
    extends 'B1';

    has c1_1 => (
        is      => 'ro',
        T1_1    => 'should not stick',
        default => 'c1_1.v',
    );

}

check_class(
    'C1',
    {
        b1_1 => 'b1_1.v',
        c1_1 => 'c1_1.v',
    },
    {
        T1_1 => {
            b1_1 => 'b1_1.t1_1',
        },
    },
    $map, '<B1'
);


{
    package C2;

    use Moo;
    extends 'B2';

    has c2_1 => (
        is      => 'ro',
        T2_1    => 'should not stick',
        default => 'c2_1.v',
    );

}

check_class(
    'C2',
    {
        b2_1 => 'b2_1.v',
        c2_1 => 'c2_1.v',
    },
    {
        T2_1 => {
            b2_1 => 'b2_1.t2_1',
        },
    },
    $map, '<B2'
);


{
    package C3;

    use Moo;
    extends 'B3';

    has c3_1 => (
        is      => 'ro',
        T1_1    => 'should not stick',
        T2_1    => 'should not stick',
        default => 'c3_1.v',
    );

}

check_class(
    'C3',
    {
        b3_1 => 'b3_1.v',
        c3_1 => 'c3_1.v',
    },
    {
        T1_1 => {
            b3_1 => 'b3_1.t1_1',
        },
        T2_1 => {
            b3_1 => 'b3_1.t2_1',
        },
    },
    $map, '<B3'
);

{
    package C31;

    use Moo;
    extends 'B4';

    has c31_1 => (
        is      => 'ro',
        T1_1    => 'should not stick',
        T2_1    => 'should not stick',
        default => 'c31_1.v',
    );

}

check_class(
    'C31',
    {
        b4_1  => 'b4_1.v',
        c31_1 => 'c31_1.v',
    },
    {
        T1_1 => {
            b4_1 => 'b4_1.t1_1',
        },
        T2_1 => {
            b4_1 => 'b4_1.t2_1',
        },
    },
    $map, '<B4'
);

{
    package C4;

    use Moo;
    extends 'B1';

    with 'R1';

    has c4_1 => (
        is      => 'ro',
        T1_1    => 'should not stick',
        default => 'c4_1.v',
    );

}

check_class(
    'C4',
    {
        b1_1 => 'b1_1.v',
        c4_1 => 'c4_1.v',
        r1_1 => 'r1_1.v',
    },
    {
        T1_1 => {
            b1_1 => 'b1_1.t1_1',
            r1_1 => 'r1_1.t1_1',
            r1_2 => 'r1_2.t1_1',
        },
        T1_2 => {
            r1_1 => 'r1_1.t1_2',
        },
    },
    $map,
    '<B1,wR1',
);

{
    package C5;

    use Moo;
    extends 'C4';

    use R1;
    use R2;

    has c5_1 => (
        is      => 'ro',
        default => 'c5_1.v',
        T1_1    => 'c5_1.t1_1',
        T2_1    => 'c5_1.t2_1',
    );

}

check_class(
    'C5',
    {
        b1_1 => 'b1_1.v',
        c4_1 => 'c4_1.v',
        c5_1 => 'c5_1.v',
        r1_1 => 'r1_1.v',
        r2_1 => 'r2_1.v',
    },
    {
        T1_1 => {
            b1_1 => 'b1_1.t1_1',
            c5_1 => 'c5_1.t1_1',
            r1_1 => 'r1_1.t1_1',
            r1_2 => 'r1_2.t1_1',
        },
        T1_2 => {
            r1_1 => 'r1_1.t1_2',
        },
        T2_1 => {
            c5_1 => 'c5_1.t2_1',
            r2_1 => 'r2_1.t2_1',
            r2_2 => 'r2_2.t2_1',
        },
        T2_2 => {
            r2_1 => 'r2_1.t2_2',
        },
    },
    $map,
    '<C4,R1,R2',

);

{
    package C6;

    use Moo;
    extends 'B1';

    with 'R1';
    with 'R2';

    has c6_1 => (
        is      => 'ro',
        default => 'c6_1.v',
        T1_1    => 'should not stick',
        T2_1    => 'should not stick',
    );

}

check_class(
    'C6',
    {
        b1_1 => 'b1_1.v',
        c6_1 => 'c6_1.v',
        r1_1 => 'r1_1.v',
        r2_1 => 'r2_1.v',
    },
    {
        T1_1 => {
            b1_1 => 'b1_1.t1_1',
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
    $map,
    '<B1,wR1,wR2',
);

{
    package C7;

    use Moo;
    extends 'B2';

    with 'R1';
    with 'R2';

    has c7_1 => (
        is      => 'ro',
        default => 'c7_1.v',
        T1_1    => 'should not stick',
        T2_1    => 'should not stick',
    );

}

check_class(
    'C7',
    {
        b2_1 => 'b2_1.v',
        c7_1 => 'c7_1.v',
        r1_1 => 'r1_1.v',
        r2_1 => 'r2_1.v',
    },
    {
        T1_1 => {
            r1_1 => 'r1_1.t1_1',
            r1_2 => 'r1_2.t1_1',
        },
        T1_2 => {
            r1_1 => 'r1_1.t1_2',
        },
        T2_1 => {
            b2_1 => 'b2_1.t2_1',
            r2_1 => 'r2_1.t2_1',
            r2_2 => 'r2_2.t2_1',
        },
        T2_2 => {
            r2_1 => 'r2_1.t2_2',
        },
    },
    $map,
    '<B2,wR1,wR2',
);

{
    package C8;

    use Moo;
    extends 'B3';

    with 'R1';
    with 'R2';

    has c8_1 => (
        is      => 'ro',
        default => 'c8_1.v',
        T1_1    => 'should not stick',
        T2_1    => 'should not stick',
    );

}

check_class(
    'C8',
    {
        b3_1 => 'b3_1.v',
        c8_1 => 'c8_1.v',
        r1_1 => 'r1_1.v',
        r2_1 => 'r2_1.v',
    },
    {
        T1_1 => {
            b3_1 => 'b3_1.t1_1',
            r1_1 => 'r1_1.t1_1',
            r1_2 => 'r1_2.t1_1',
        },
        T1_2 => {
            r1_1 => 'r1_1.t1_2',
        },
        T2_1 => {
            b3_1 => 'b3_1.t2_1',
            r2_1 => 'r2_1.t2_1',
            r2_2 => 'r2_2.t2_1',
        },
        T2_2 => {
            r2_1 => 'r2_1.t2_2',
        },
    },
    $map,
    '<B3,wR1,wR2',
);

{
    package R3;
    use Moo::Role;
    with 'R1';

    # this tag shouldn't stick as this isn't a tag role.
    has r3_1 => (
        is   => 'ro',
        T1_1 => 'r3_1.t1_1',
    );
}

{
    package C9;
    use Moo;
    with 'R3';

    has c9_1 => (
        is      => 'rw',
        T1_1    => 'should not stick',
        default => 'c9_1.v',
    );
}

check_class(
    'C9',
    {
        t1_1 => 't1_1.v',
        r1_1 => 'r1_1.v',
        r1_2 => 'r1_2.v',
        c9_1 => 'c9_1.v',
    },
    {
        T1_1 => {
            r1_1 => 'r1_1.t1_1',
            r1_2 => 'r1_2.t1_1',
        },
        T1_2 => {
            r1_1 => 'r1_1.t1_2',
        },
    },
    $map,
    'wR3',
);

{
    package C10;
    use Moo;

    extends 'B1', 'B2';

    use R1;
    use R2;

    has c10_1 => (
        is      => 'rw',
        T1_1    => 'c10_1.t1_1',
        T2_1    => 'c10_1.t2_1',
        default => 'c10_1.v',
    );
}

TODO : {

    local $TODO = "Moo has issues with attributes inherited from multiple superclasses";

check_class(
    'C10',
    {
        b1_1 => 'b1_1.v',
        b2_1 => 'b2_1.v',
        t1_1 => 't1_1.v',
        t2_1 => 't2_1.v',
        r1_1 => 'r1_1.v',
        r1_2 => 'r1_2.v',
        c10_1 => 'c10_1.v',
    },
    {
        T1_1 => {
	    b1_1   => 'b1_1.t1_1',
	    c10_1 => 'c10_1.t1_1',
            r1_1 => 'r1_1.t1_1',
            r1_2 => 'r1_2.t1_1',
        },
        T1_2 => {
            r1_1 => 'r1_1.t1_2',
        },
        T2_1 => {
	    b2_1  => 'b2_1.t2_1',
	    c10_1 => 'c10_1.t2_1',
            r2_1 => 'r2_1.t2_1',
            r2_2 => 'r2_2.t2_1',
        },
        T2_2 => {
            r2_1 => 'r2_1.t2_2',
        },
    },
    $map,
    '<B1, <B2, R1, R2',
);

}

done_testing;
