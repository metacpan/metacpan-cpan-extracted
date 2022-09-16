#!perl

use v5.10;
use Test2::V0;
use Test::Lib;
use My::Test;

my %map = (
    R1  => 'T1',
    R2  => 'T2',
    R3  => 'wR1',
    T12 => 'T1,T2',
);

sub name { My::Test::name( \%map, @_ ) }

subtest( $_, \&test_it, $_ ) for ( 'My::Class', 'My::Role' );

sub test_it {

    my $type = shift;

    subtest name( 'B1', 'T1' ) => sub {

        my ( $class, $is_role ) = load B1 => $type;

        is(
            $class->new,
            object {
                call b1_1 => 'b1_1.v';
            },
        );

        is(
            $class->_tags,
            hash {
                field T1_1 => hash {
                    field b1_1 => 'b1_1.t1_1';
                };
            },
        );
    };

    subtest name( 'B2', 'T2' ) => sub {

        my ( $class, $is_role ) = load B2 => $type;

        is(
            $class->new,
            object {
                call b2_1 => 'b2_1.v';
            },
        );

        is(
            $class->_tags,
            hash {
                field T2_1 => hash {
                    field b2_1 => 'b2_1.t2_1';
                    end();
                };
                end();
            },
        );

    };


    subtest name( 'B3', 'T1,T2' ) => sub {

        my ( $class, $is_role ) = load B3 => $type;

        is(
            $class->new,
            object {
                call b3_1 => 'b3_1.v';
            } );

        is(
            $class->_tags,
            hash {
                field T1_1 => hash {
                    field b3_1 => 'b3_1.t1_1';
                    end();
                };
                field T2_1 => hash {
                    field b3_1 => 'b3_1.t2_1';
                    end();
                };
                end();
            },
        );
    };

    subtest name( 'B4', 'T12' ) => sub {

        my ( $class, $is_role ) = load B4 => $type;

        is(
            $class->new,
            object {
                call b4_1  => 'b4_1.v';
                call t12_1 => 't12_1.v';
            },
        );

        is(
            $class->_tags,
            hash {
                field T1_1 => hash {
                    field b4_1 => 'b4_1.t1_1';
                    end();
                };
                field T2_1 => hash {
                    field b4_1 => 'b4_1.t2_1';
                    end();
                };
                end();
            },
        );

    };

    subtest name( 'C1', '<B1' ) => sub {

        my ( $class, $is_role ) = load C1 => $type;
        is(
            $class->new,
            object {
                call b1_1 => 'b1_1.v';
                call c1_1 => 'c1_1.v';
            },
        );
        is(
            $class->_tags,
            hash {
                field T1_1 => hash {
                    field b1_1 => 'b1_1.t1_1';
                    end();
                };
                end();
            },
        );
    };

    subtest name( 'C2', '<B2' ) => sub {

        my ( $class, $is_role ) = load C2 => $type;

        is(
            $class->new,
            object {
                call b2_1 => 'b2_1.v';
                call c2_1 => 'c2_1.v';
            },
        );
        is(
            $class->_tags,
            hash {
                field T2_1 => hash {
                    field b2_1 => 'b2_1.t2_1';
                    end();
                };
                end();
            },
        );
    };

    subtest name( 'C3', '<B3' ) => sub {

        my ( $class, $is_role ) = load C3 => $type;

        is(
            $class->new,
            object {
                call b3_1 => 'b3_1.v';
                call c3_1 => 'c3_1.v';
            },
        );
        is(
            $class->_tags,
            hash {
                field T1_1 => hash {
                    field b3_1 => 'b3_1.t1_1';
                    end();
                };
                field T2_1 => hash {
                    field b3_1 => 'b3_1.t2_1';
                    end();
                };
                end();
            },
        );
    };

    subtest name( 'C31', '<B4' ) => sub {

        my ( $class, $is_role ) = load C31 => $type;

        is(
            $class->new,
            object {
                call b4_1  => 'b4_1.v';
                call c31_1 => 'c31_1.v';
            },
        );
        is(
            $class->_tags,
            hash {
                field T1_1 => hash {
                    field b4_1 => 'b4_1.t1_1';
                    end();
                };
                field T2_1 => hash {
                    field b4_1 => 'b4_1.t2_1';
                    end();
                };
                end();
            },
        );

    };

    subtest name( 'C4', '<B1,wR1' ) => sub {

        my ( $class, $is_role ) = load C4 => $type;
        is(
            $class->new,
            object {
                call b1_1 => 'b1_1.v';
                call c4_1 => 'c4_1.v';
                call r1_1 => 'r1_1.v';
            },
        );
        is(
            $class->_tags,
            hash {
                field T1_1 => hash {
                    field b1_1 => 'b1_1.t1_1';
                    field r1_1 => 'r1_1.t1_1';
                    field r1_2 => 'r1_2.t1_1';
                    field c4_1 => 'c4_1.t1_1' if $is_role;
                    end();
                };
                field T1_2 => hash {
                    field r1_1 => 'r1_1.t1_2';
                    end();
                };
                end();
            },
        );
    };


    subtest name( 'C5', '<C4,R1,R2' ) => sub {

        my ( $class, $is_role ) = load C5 => $type;

        is(
            $class->new,
            object {
                call b1_1 => 'b1_1.v';
                call c4_1 => 'c4_1.v';
                call c5_1 => 'c5_1.v';
                call r1_1 => 'r1_1.v';
                call r2_1 => 'r2_1.v';
            },
        );

        is(
            $class->_tags,
            hash {
                field T1_1 => hash {
                    field b1_1 => 'b1_1.t1_1';
                    field c4_1 => 'c4_1.t1_1' if $is_role;
                    field c5_1 => 'c5_1.t1_1';
                    field r1_1 => 'r1_1.t1_1';
                    field r1_2 => 'r1_2.t1_1';
                    end();
                };
                field T1_2 => hash {
                    field r1_1 => 'r1_1.t1_2';
                    end();
                };
                field T2_1 => hash {
                    field c5_1 => 'c5_1.t2_1';
                    field r2_1 => 'r2_1.t2_1';
                    field r2_2 => 'r2_2.t2_1';
                    end();
                };
                field T2_2 => hash {
                    field r2_1 => 'r2_1.t2_2';
                    end();
                };
            },
        );

    };

    subtest name( 'C6', '<B1,wR1,wR2' ) => sub {

        my ( $class, $is_role ) = load C6 => $type;

        is(
            $class->new,
            object {
                call b1_1 => 'b1_1.v';
                call c6_1 => 'c6_1.v';
                call r1_1 => 'r1_1.v';
                call r2_1 => 'r2_1.v';
            },
        );
        is(
            $class->_tags,
            hash {
                field T1_1 => hash {
                    field b1_1 => 'b1_1.t1_1';
                    field r1_1 => 'r1_1.t1_1';
                    field r1_2 => 'r1_2.t1_1';
                    field c6_1 => 'c6_1.t1_1' if $is_role;
                    end();
                };
                field T1_2 => hash {
                    field r1_1 => 'r1_1.t1_2';
                    end();
                };
                field T2_1 => hash {
                    field r2_1 => 'r2_1.t2_1';
                    field r2_2 => 'r2_2.t2_1';
                    field c6_1 => 'c6_1.t2_1' if $is_role;
                    end();
                };
                field T2_2 => hash {
                    field r2_1 => 'r2_1.t2_2';
                    end();
                };
                end();
            },
        );
    };

    subtest name( 'C7', '<B2,wR1,wR2' ) => sub {

        my ( $class, $is_role ) = load C7 => $type;

        is(
            $class->new,
            object {
                call b2_1 => 'b2_1.v';
                call c7_1 => 'c7_1.v';
                call r1_1 => 'r1_1.v';
                call r2_1 => 'r2_1.v';
            },
        );

        is(
            $class->_tags,
            hash {
                field T1_1 => hash {
                    field r1_1 => 'r1_1.t1_1';
                    field r1_2 => 'r1_2.t1_1';
                    field c7_1 => 'c7_1.t1_1' if $is_role;
                    end();
                };
                field T1_2 => hash {
                    field r1_1 => 'r1_1.t1_2';
                    end();
                };
                field T2_1 => hash {
                    field b2_1 => 'b2_1.t2_1';
                    field r2_1 => 'r2_1.t2_1';
                    field r2_2 => 'r2_2.t2_1';
                    field c7_1 => 'c7_1.t2_1' if $is_role;
                    end();
                };
                field T2_2 => hash {
                    field r2_1 => 'r2_1.t2_2';
                    end();
                };
                end();
            },
        );
    };

    subtest name( 'C8', '<B3,wR1,wR2' ) => sub {

        my ( $class, $is_role ) = load C8 => $type;

        is(
            $class->new,
            object {
                call b3_1 => 'b3_1.v';
                call c8_1 => 'c8_1.v';
                call r1_1 => 'r1_1.v';
                call r2_1 => 'r2_1.v';
            },
        );

        is(
            $class->_tags,
            hash {
                field T1_1 => hash {
                    field b3_1 => 'b3_1.t1_1';
                    field r1_1 => 'r1_1.t1_1';
                    field r1_2 => 'r1_2.t1_1';
                    field c8_1 => 'c8_1.t1_1' if $is_role;
                    end;
                };
                field T1_2 => hash {
                    field r1_1 => 'r1_1.t1_2';
                    end;
                };
                field T2_1 => hash {
                    field b3_1 => 'b3_1.t2_1';
                    field r2_1 => 'r2_1.t2_1';
                    field r2_2 => 'r2_2.t2_1';
                    field c8_1 => 'c8_1.t2_1' if $is_role;
                    end;
                };
                field T2_2 => hash {
                    field r2_1 => 'r2_1.t2_2';
                    end;
                };
                end;
            },
        );
    };

    subtest name( 'C9', 'wR3' ) => sub {

        my ( $class, $is_role ) = load C9 => $type;

        is(
            $class->new,
            object {
                call t1_1 => 't1_1.v';
                call r1_1 => 'r1_1.v';
                call r1_2 => 'r1_2.v';
                call c9_1 => 'c9_1.v' if $is_role;
            },
        );
        is(
            $class->_tags,
            hash {
                field T1_1 => hash {
                    field r1_1 => 'r1_1.t1_1';
                    field r1_2 => 'r1_2.t1_1';
                    field r3_1 => 'r3_1.t1_1' if $is_role;
                    field c9_1 => 'c9_1.t1_1' if $is_role;
                    end();
                };
                field T1_2 => hash {
                    field r1_1 => 'r1_1.t1_2';
                    end();
                };
                end();
            },
        );
    };


    todo
      "Moo has issues with attributes inherited from multiple superclasses" =>
      sub {

        subtest name( 'C10', '<B1, <B2, R1, R2' ) => sub {

            my ( $class, $is_role ) = load C10 => $type;

            is(
                $class->new,
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
                $class->_tags,
                hash {
                    field T1_1 => hash {
                        field b1_1  => 'b1_1.t1_1';
                        field c10_1 => 'c10_1.t1_1';
                        field r1_1  => 'r1_1.t1_1';
                        field r1_2  => 'r1_2.t1_1';
                        end();
                    };
                    field T1_2 => hash {
                        field r1_1 => 'r1_1.t1_2';
                        end();
                    };
                    field T2_1 => hash {
                        field b2_1  => 'b2_1.t2_1';
                        field c10_1 => 'c10_1.t2_1';
                        field r2_1  => 'r2_1.t2_1';
                        field r2_2  => 'r2_2.t2_1';
                        end();
                    };
                    field T2_2 => hash {
                        field r2_1 => 'r2_1.t2_2';
                        end();
                    };
                    end();
                },
            );
        };
      };
}

done_testing;
