#! perl

use Test2::V0;
use Test2::Tools::PDL;

use Test::Lib;

use Hash::Wrap;
use My::Class;
use My::Util;
use PDL::Lite;

use Scalar::Util qw[ refaddr ];

sub test_obj {

    My::Class->new(
        p1 => PDL->sequence( 5 ),
        p2 => PDL->sequence( 5 ) + 1,
    );

}

sub build_expected {

    my %data = @_;

    My::Class->new(
        p1 => PDL->new( $data{p1} ),
        p2 => PDL->new( $data{p2} ),
    );

}


sub test_inplace {

    my $context = context();

    my ( $sub, $expected ) = @_;

    subtest 'inplace' => sub {

        my $orig = test_obj;

        my $new = $sub->( $orig->inplace );

        test_inplace_flat_obj( $orig, $new, $expected );
    };

    $context->release;
}

sub test_not_inplace {

    my $context = context();

    my ( $sub, $expected ) = @_;

    subtest '! inplace' => sub {

        my $orig = test_obj;

        my %data;

        for my $p ( 'p1', 'p2' ) {
            $data{$p} = wrap_hash( {
                    refaddr => refaddr( $orig->$p->get_dataref ),
                    copy    => $orig->$p->copy,
                },
            );
        }

        my $new = $sub->( $orig );

        test_not_inplace_flat_obj( $orig, $new, $expected, %data );
    };

    $context->release;
}


sub test {
    my $context = context();
    my ( $label, $sub, %expected ) = @_;
    my $expected = build_expected( %expected );

    subtest $label => sub {
        test_inplace( $sub, $expected );
        test_not_inplace( $sub, $expected );
    };

    $context->release;
}

test(
    "where",
    sub { $_[0]->where( $_[0]->p1 % 2 ) },
    p1 => [ 1, 3 ],
    p2 => [ 2, 4 ],
);

test(
    "index",
    sub { $_[0]->index( PDL->new( 0, 1, 3 ) ) },
    p1 => [ 0, 1, 3 ],
    p2 => [ 1, 2, 4 ],
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
