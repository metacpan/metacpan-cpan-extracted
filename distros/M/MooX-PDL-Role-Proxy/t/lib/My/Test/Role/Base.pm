package My::Test::Role::Base;

use Test2::V0;
use Test2::Tools::PDL;
use Scalar::Util qw( refaddr );

use Role::Tiny;

use namespace::clean;

requires qw(
  build_expected
  test_inplace
  test_not_inplace
);

sub test {
    my $class = shift;

    my $context = context();
    my ( $label, $sub, %expected ) = @_;

    my $expected = $class->build_expected( %expected );


    subtest $label => sub {
        $class->test_inplace( $sub, $expected );
        $class->test_not_inplace( $sub, $expected );
    };

    $context->release;
}

sub test_inplace_flat_obj {

    my $class = shift;

    my ( $orig, $new, $expected ) = @_;

    my $context = context();

    ref_is( $new, $orig, "same object returned" );

    for my $p ( 'p1', 'p2' ) {

        subtest $p => sub {

            ref_is( $orig->$p->get_dataref,
                $new->$p->get_dataref, "refaddr orig.$p == new.$p" );

            pdl_is( $orig->$p, $expected->$p, "orig.$p: contents" );
        };
    }

    $context->release;
}


sub test_not_inplace_flat_obj {

    my $class = shift;

    my ( $orig, $new, $expected, %data ) = @_;

    my $context = context();

    ref_is_not( $orig, $new, "new object returned" );

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
