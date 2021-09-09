#! perl

use Test::Lib;
use Test2::V0;
use Test2::Tools::PDL;

use Scalar::Util qw[ refaddr ];

use My::Test::Role;

our $pbase = PDL->sequence( 5 );

package Test {

    use Test2::V0;
    use Role::Tiny::With;
    use PDL::Lite;

    with My::Test::Role::Nested();

    sub test_obj {
        my $class = shift;

        $class->nested_test_class_new(
            c1 => $class->test_class_new(

                p1 => $::pbase +0,     # 0 1 2 3 4
                p2 => $::pbase + 1,    # 1 2 3 4 5
            ),
            c2 => $class->test_class_new(
                p1 => $::pbase + 3,    # 3 4 5 6 7
                p2 => $::pbase + 2,    # 2 3 4 5 6
            ),
        );
    }
}

Test->test(
    "where",
    sub {
        $_[0]->where( $pbase % 2 );
    },
    c1 => {
        p1 => [ 1, 3 ],
        p2 => [ 2, 4 ],
    },
    c2 => {
        p1 => [ 4, 6 ],
        p2 => [ 3, 5 ],
    },
);

Test->test(
    "index",
    sub { $_[0]->index( PDL->new( 0, 1, 3 ) ) },
    c1 => {
        p1 => [ 0, 1, 3 ],
        p2 => [ 1, 2, 4 ],
    },
    c2 => {
        p1 => [ 3, 4, 6 ],
        p2 => [ 2, 3, 5 ],
    },
);


subtest 'at' => sub {
    my $orig = Test->test_obj;
    my $at   = $orig->at( 3 );

    subtest 'c1' => sub {
        is( $at->c1->p1, 3, 'p1' );
        is( $at->c1->p2, 4, 'p2' );
    };

    subtest 'c2' => sub {
        is( $at->c2->p1, 6, 'p1' );
        is( $at->c2->p2, 5, 'p2' );
    };
};


subtest 'copy' => sub {

    my $orig = Test->test_obj;

    my $new = $orig->copy;

    isnt( refaddr( $new ), refaddr( $orig ), "same object not returned" );

    for my $c ( 'c1', 'c2' ) {

        subtest $c => sub {
            isnt(
                refaddr( $new->$c ),
                refaddr( $orig->$c ),
                "same object not returned"
            );

            for my $p ( 'p1', 'p2' ) {

                subtest $p => sub {

                    isnt(
                        refaddr( $orig->$c->$p->get_dataref ),
                        refaddr( $new->$c->$p->get_dataref ),
                        "same ndarray not returned"
                    );

                    pdl_is( $new->$c->$p, $orig->$c->$p, 'contents' );

                };
            }
        };
    }
};

subtest 'sever' => sub {

    my $orig = Test->test_obj;

    my $new = $orig->index( PDL->new( 0, 1, 3 ) );

    subtest 'pre-sever' => sub {

        for my $c ( 'c1', 'c2' ) {

            subtest $c => sub {

                for my $p ( 'p1', 'p2' ) {

                    subtest $p => sub {

                        $new->$c->$p->set( 0, 22 );
                        is( $orig->$c->$p->at( 0 ), 22, 'set works' );
                    };
                }

            };

        }
    };

    $new->sever;

    subtest 'post-sever' => sub {

        for my $c ( 'c1', 'c2' ) {

            subtest $c => sub {

                for my $p ( 'p1', 'p2' ) {

                    subtest $p => sub {

                        $new->$c->$p->set( 0, 24 );
                        is( $new->$c->$p->at( 0 ),  24, 'new set works' );
                        is( $orig->$c->$p->at( 0 ), 22, 'original unchanged' );
                    };
                }

            };

        }
    };

};

done_testing;
