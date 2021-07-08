#! perl

use Test::Lib;
use Test2::V0;
use Test2::Tools::PDL;

use Scalar::Util qw[ refaddr ];

package Test {

    use Test2::V0;
    use Role::Tiny::With;
    use My::Class;
    use PDL::Lite;

    with 'My::Test::Role::Single';

    sub test_obj {
        my $class = shift;

        $class->test_class_new(
            p1 => PDL->sequence( 5 ),
            p2 => PDL->sequence( 5 ) + 1,
        );

    }
}


Test->test(
    "where",
    sub { $_[0]->where( $_[0]->p1 % 2 ) },
    p1 => [ 1, 3 ],
    p2 => [ 2, 4 ],
);

Test->test(
    "index",
    sub { $_[0]->index( PDL->new( 0, 1, 3 ) ) },
    p1 => [ 0, 1, 3 ],
    p2 => [ 1, 2, 4 ],
);

Test->test(
    "copy",
    sub { $_[0]->copy },
    p1 => [ 0, 1, 2, 3, 4 ],
    p2 => [ 1, 2, 3, 4, 5 ],
);

subtest 'at' => sub {
    my $o  = Test->test_obj;
    my $at = $o->at( 3 );
    is( $at->p1, 3, 'p1' );
    is( $at->p2, 4, 'p2' );
};


subtest 'sever' => sub {

    my $o = Test->test_obj;

    my $n = $o->index( PDL->new( 0, 1, 3 ) );

    $n->p1->set( 0, 22 );

    is( $o->p1->at( 0 ), 22, 'not severed' );

    my $c = $n->sever;
    $n->p1->set( 0, 24 );
    is( $o->p1->at( 0 ), 22, 'severed' );
    ref_is( $c, $n, "sever returns self" );
};


done_testing;
