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

use B1;

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

use B2;

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


use B3;
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

use B4;
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


use C1;
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

use C2;
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

use C3;
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

use C31;
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

use C4;
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

use C5;
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

use C6;
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

use C7;
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

use C8;
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

use C9;
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

use C10;

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
