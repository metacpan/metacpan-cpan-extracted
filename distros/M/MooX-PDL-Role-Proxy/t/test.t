#! perl

use Test2::V0;
use Test2::Tools::PDL;

use Test::Lib;

use My::Class;
use PDL::Lite;

use Scalar::Util qw[ refaddr ];

sub test_obj {

    my $o = My::Class->new;
    my $tmp;
    ( $tmp = $o->p1 ) .= PDL->sequence( 5 );
    ( $tmp = $o->p2 ) .= $o->p1 + 1;

    return $o;
}

sub test_inplace {

    my $context = context();

    my ( $sub, $p1_res, $p2_res ) = @_;

    subtest 'inplace' => sub {

        my $o = test_obj;

        my $n = $sub->( $o->inplace );

        is( refaddr( $n ), refaddr( $o ), "same object returned" );

        is(
            refaddr( $o->p1->get_dataref ),
            refaddr( $n->p1->get_dataref ),
            'refaddr o.p1 == n.p1'
        );
        is(
            refaddr( $o->p2->get_dataref ),
            refaddr( $n->p2->get_dataref ),
            'refaddr o.p2 == n.p2'
        );

        pdl_is( $o->p1, $p1_res, 'o.p1: contents' );
        pdl_is( $o->p2, $p2_res, 'o.p2: contents' );
    };

    $context->release;
}

sub test_not_inplace {

    my $context = context();

    my ( $sub, $p1_res, $p2_res ) = @_;

    subtest '! inplace' => sub {

        my $o = test_obj;

        my $p1_addr = refaddr( $o->p1->get_dataref );
        my $p2_addr = refaddr( $o->p2->get_dataref );

        my $p1 = $o->p1->copy;
        my $p2 = $o->p2->copy;

        my $n = $sub->( $o );

        isnt( refaddr( $n ), refaddr( $o ), "new object returned" );

        is( refaddr( $o->p1->get_dataref ), $p1_addr, 'o.p1: same refaddr' );
        is( refaddr( $o->p2->get_dataref ), $p2_addr, 'o.p2: same refaddr' );

        isnt( refaddr( $n->p1->get_dataref ),
            $p1_addr, 'n.p1: different refaddr' );
        isnt( refaddr( $n->p2->get_dataref ),
            $p2_addr, 'n.p2: different refaddr' );

        pdl_is( $o->p1, $p1, 'o.p1: contents' );
        pdl_is( $o->p2, $p2, 'o.p2: contents' );

        pdl_is( $n->p1, $p1_res, 'n.p1: contents' );
        pdl_is( $n->p2, $p2_res, 'n.p2: contents' );
    };

    $context->release;
}


sub test {
    my $context = context();
    my $label   = shift;
    my @args    = @_;

    subtest $label => sub {
        test_inplace( @args );
        test_not_inplace( @args );
    };

    $context->release;
}

test(
    "where",
    sub { $_[0]->where( $_[0]->p1 % 2 ) },
    PDL->new( 1, 3 ),
    PDL->new( 2, 4 ) );

test(
    "index",
    sub { $_[0]->index( PDL->new( 0, 1, 3 ) ) },
    PDL->new( 0, 1, 3 ),
    PDL->new( 1, 2, 4 ),
);


subtest 'at' => sub {
    my $o  = test_obj;
    my $at = $o->at( 3 );
    is( $at->p1, 3, 'p1' );
    is( $at->p2, 4, 'p2' );
};


subtest 'copy' => sub {

    my $o = test_obj;

    my $n = $o->copy;

    isnt( refaddr( $n ), refaddr( $o ), "same object returned" );

    isnt(
        refaddr( $o->p1->get_dataref ),
        refaddr( $n->p1->get_dataref ),
        'refaddr o.p1 != n.p1'
    );

    isnt(
        refaddr( $o->p2->get_dataref ),
        refaddr( $n->p2->get_dataref ),
        'refaddr o.p2 != n.p2'
    );

    pdl_is( $n->p1, $o->p1, 'o.p1: contents' );
    pdl_is( $n->p2, $o->p2, 'o.p2: contents' );

};

subtest 'sever' => sub {

    my $o = test_obj;

    my $n = $o->index( PDL->new( 0, 1, 3 ) );

    $n->p1->set( 0, 22 );

    is( $o->p1->at( 0 ), 22, 'not severed' );

    $n->sever;
    $n->p1->set( 0, 24 );
    is( $o->p1->at( 0 ), 22, 'severed' );
};



done_testing;
