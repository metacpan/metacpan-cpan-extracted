#!perl

use Test2::V0;
use Test::Lib;
use My::Test;

use Data::Dump qw[ pp ];

my %map = (
    R1  => 'T1',
    R2  => 'T2',
    R3  => 'wR1',
    T12 => 'T1,T2',
);

sub name { My::Test::name( \%map, @_ ) }

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

subtest name( 'B1', 'T1' ) => sub {

    is(
        B1->new,
        object {
            call b1_1 => 'b1_1.v';
        },
    );

    is(
        B1->_tags,
        hash {
            field T1_1 => hash {
                field b1_1 => 'b1_1.t1_1';
            };
        },
    );
};

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

subtest name( 'B2', 'T2' ) => sub {

    is(
        B2->new,
        object {
            call b2_1 => 'b2_1.v';
        },
    );

    is(
        B2->_tags,
        hash {
            field T2_1 => hash {
                field b2_1 => 'b2_1.t2_1';
            };
        },
    );

};


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

subtest name( 'B3', 'T1,T2' ) => sub {

    is(
        B3->new,
        object {
            call b3_1 => 'b3_1.v';
        } );

    is(
        B3->_tags,
        hash {
            field T1_1 => hash {
                field b3_1 => 'b3_1.t1_1';
            };
            field T2_1 => hash {
                field b3_1 => 'b3_1.t2_1';
            };
        },
    );
};

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

subtest name( 'B4', 'T12' ) => sub {

    is(
        B4->new,
        object {
            call b4_1  => 'b4_1.v';
            call t12_1 => 't12_1.v';
        },
    );

    is(
        B4->_tags,
        hash {
            field T1_1 => hash {
                field b4_1 => 'b4_1.t1_1';
            };
            field T2_1 => hash {
                field b4_1 => 'b4_1.t2_1';
            };
        },
    );

};


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

subtest name( 'C1', '<B1' ) => sub {

    is(
        C1->new,
        object {
            call b1_1 => 'b1_1.v';
            call c1_1 => 'c1_1.v';
        },
    );
    is(
        C1->_tags,
        hash {
            field T1_1 => hash {
                field b1_1 => 'b1_1.t1_1';
            };
        },
    );
};

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

subtest name( 'C2', '<B2' ) => sub {

    is(
        C2->new,
        object {
            call b2_1 => 'b2_1.v';
            call c2_1 => 'c2_1.v';
        },
    );
    is(
        C2->_tags,
        hash {
            field T2_1 => hash {
                field b2_1 => 'b2_1.t2_1';
            };
        },
    );
};

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

subtest name( 'C3', '<B3' ) => sub {

    is(
        C3->new,
        object {
            call b3_1 => 'b3_1.v';
            call c3_1 => 'c3_1.v';
        },
    );
    is(
        C3->_tags,
        hash {
            field T1_1 => hash {
                field b3_1 => 'b3_1.t1_1';
            };
            field T2_1 => hash {
                field b3_1 => 'b3_1.t2_1';
            };
        },
    );
};
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

subtest name( 'C31', '<B4' ) => sub {

    is(
        C31->new,
        object {
            call b4_1  => 'b4_1.v';
            call c31_1 => 'c31_1.v';
        },
    );
    is(
        C31->_tags,
        hash {
            field T1_1 => hash {
                field b4_1 => 'b4_1.t1_1';
            };
            field T2_1 => hash {
                field b4_1 => 'b4_1.t2_1';
            };
        },
    );

};

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

subtest name( 'C4', '<B1,wR1' ) => sub {

    is(
        C4->new,
        object {
            call b1_1 => 'b1_1.v';
            call c4_1 => 'c4_1.v';
            call r1_1 => 'r1_1.v';
        },
    );
    is(
        C4->_tags,
        hash {
            field T1_1 => hash {
                field b1_1 => 'b1_1.t1_1';
                field r1_1 => 'r1_1.t1_1';
                field r1_2 => 'r1_2.t1_1';
            };
            field T1_2 => hash {
                field r1_1 => 'r1_1.t1_2';
            };
        },
    );
};

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

subtest name( 'C5', '<C4,R1,R2' ) => sub {

    is(
        C5->new,
        object {
            call b1_1 => 'b1_1.v';
            call c4_1 => 'c4_1.v';
            call c5_1 => 'c5_1.v';
            call r1_1 => 'r1_1.v';
            call r2_1 => 'r2_1.v';
        },
    );

    is(
        C5->_tags,
        hash {
            field T1_1 => hash {
                field b1_1 => 'b1_1.t1_1';
                field c5_1 => 'c5_1.t1_1';
                field r1_1 => 'r1_1.t1_1';
                field r1_2 => 'r1_2.t1_1';
            };
            field T1_2 => hash {
                field r1_1 => 'r1_1.t1_2';
            };
            field T2_1 => hash {
                field c5_1 => 'c5_1.t2_1';
                field r2_1 => 'r2_1.t2_1';
                field r2_2 => 'r2_2.t2_1';
            };
            field T2_2 => hash {
                field r2_1 => 'r2_1.t2_2';
            };
        },
    );

};

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

subtest name( 'C6', '<B1,wR1,wR2' ) => sub {

    is(
        C6->new,
        object {
            call b1_1 => 'b1_1.v';
            call c6_1 => 'c6_1.v';
            call r1_1 => 'r1_1.v';
            call r2_1 => 'r2_1.v';
        },
    );
    is(
        C6->_tags,
        hash {
            field T1_1 => hash {
                field b1_1 => 'b1_1.t1_1';
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
    );
};

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

subtest name( 'C7', '<B2,wR1,wR2' ) => sub {

    is(
        C7->new,
        object {
            call b2_1 => 'b2_1.v';
            call c7_1 => 'c7_1.v';
            call r1_1 => 'r1_1.v';
            call r2_1 => 'r2_1.v';
        },
    );

    is(
        C7->_tags,
        hash {
            field T1_1 => hash {
                field r1_1 => 'r1_1.t1_1';
                field r1_2 => 'r1_2.t1_1';
            };
            field T1_2 => hash {
                field r1_1 => 'r1_1.t1_2';
            };
            field T2_1 => hash {
                field b2_1 => 'b2_1.t2_1';
                field r2_1 => 'r2_1.t2_1';
                field r2_2 => 'r2_2.t2_1';
            };
            field T2_2 => hash {
                field r2_1 => 'r2_1.t2_2';
            };
        },
    );
};

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

subtest name( 'C8', '<B3,wR1,wR2' ) => sub {

    is(
        C8->new,
        object {
            call b3_1 => 'b3_1.v';
            call c8_1 => 'c8_1.v';
            call r1_1 => 'r1_1.v';
            call r2_1 => 'r2_1.v';
        },
    );

    is(
        C8->_tags,
        hash {
            field T1_1 => hash {
                field b3_1 => 'b3_1.t1_1';
                field r1_1 => 'r1_1.t1_1';
                field r1_2 => 'r1_2.t1_1';
            };
            field T1_2 => hash {
                field r1_1 => 'r1_1.t1_2';
            };
            field T2_1 => hash {
                field b3_1 => 'b3_1.t2_1';
                field r2_1 => 'r2_1.t2_1';
                field r2_2 => 'r2_2.t2_1';
            };
            field T2_2 => hash {
                field r2_1 => 'r2_1.t2_2';
            };
        },
    );
};
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

subtest name( 'C9', 'wR3' ) => sub {

    is(
        C9->new,
        object {
            call t1_1 => 't1_1.v';
            call r1_1 => 'r1_1.v';
            call r1_2 => 'r1_2.v';
            call c9_1 => 'c9_1.v';
        },
    );
    is(
        C9->_tags,
        hash {
            field T1_1 => hash {
                field r1_1 => 'r1_1.t1_1';
                field r1_2 => 'r1_2.t1_1';
            };
            field T1_2 => hash {
                field r1_1 => 'r1_1.t1_2';
            };
        },
    );
};

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

todo "Moo has issues with attributes inherited from multiple superclasses" =>
  sub {

    subtest name( 'C10', '<B1, <B2, R1, R2' ) => sub {

        is(
            C10->new,
            object {
                call b1_1  => 'b1_1.v';
                call b2_1  => 'b2_1.v';
                call t1_1  => 't1_1.v';
                call t2_1  => 't2_1.v';
                call r1_1  => 'r1_1.v';
                call r1_2  => 'r1_2.v';
                call c10_1 => 'c10_1.v';
            },
        );
        is(
            C10->_tags,
            hash {
                field T1_1 => hash {
                    field b1_1  => 'b1_1.t1_1';
                    field c10_1 => 'c10_1.t1_1';
                    field r1_1  => 'r1_1.t1_1';
                    field r1_2  => 'r1_2.t1_1';
                };
                field T1_2 => hash {
                    field r1_1 => 'r1_1.t1_2';
                };
                field T2_1 => hash {
                    field b2_1  => 'b2_1.t2_1';
                    field c10_1 => 'c10_1.t2_1';
                    field r2_1  => 'r2_1.t2_1';
                    field r2_2  => 'r2_2.t2_1';
                };
                field T2_2 => hash {
                    field r2_1 => 'r2_1.t2_2';
                };
            },
        );
    };
  };

done_testing;
