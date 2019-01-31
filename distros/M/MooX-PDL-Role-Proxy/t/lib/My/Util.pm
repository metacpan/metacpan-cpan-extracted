#! perl

use Test2::API;
use Scalar::Util qw[ refaddr ];

use Exporter 'import';

our @EXPORT = qw( test_inplace_flat_obj test_not_inplace_flat_obj);

sub test_inplace_flat_obj {

    my ( $orig, $new, $expected ) = @_;

    my $context = context();

    is( refaddr( $new ), refaddr( $orig ), "same object returned" );

    for my $p ( 'p1', 'p2' ) {

        subtest $p => sub {

            is(
                refaddr( $orig->$p->get_dataref ),
                refaddr( $new->$p->get_dataref ),
                "refaddr orig.$p == new.$p"
            );

            pdl_is( $orig->$p, $expected->$p, "orig.$p: contents" );
        };
    }

    $context->release;
}


sub test_not_inplace_flat_obj {

    my ( $orig, $new, $expected, %data ) = @_;

    my $context = context();

    isnt( refaddr( $orig ), refaddr( $new ), "new object returned" );

    for my $p ( 'p1', 'p2' ) {

        subtest $p => sub {

            is( refaddr( $orig->$p->get_dataref ),
                $data{$p}->refaddr, "no change in orig.$p refaddr" );
            isnt( refaddr( $new->$p->get_dataref ),
                $data{$p}->refaddr, "new.$p: different refaddr" );

            pdl_is( $orig->$p, $data{$p}->copy, "orig.$p: same contents" );
            pdl_is( $new->$p,  $expected->$p,   "new.$p: expected contents" );
        };

    }

    $context->release;
}



1;
