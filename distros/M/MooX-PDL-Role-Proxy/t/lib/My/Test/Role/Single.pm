package My::Test::Role::Single;

use Test2::V0;
use Test2::Tools::PDL;

use Hash::Wrap;
use Scalar::Util qw[ refaddr ];
use Module::Load 'load';

use Role::Tiny;

with 'My::Test::Role::Base';

use namespace::clean;

requires 'test_obj';

sub test_class_new {
    my $class = shift;
    load $class->test_class;
    return $class->test_class->new( @_ );
}

sub test_inplace {
    my $class = shift;
    my $context = context();
    my ( $sub, $expected ) = @_;

    subtest 'inplace' => sub {
        my $orig = $class->test_obj;
        my $new = $sub->( $orig->inplace );
        $class->test_inplace_flat_obj( $orig, $new, $expected );
    };

    $context->release;
}

sub test_not_inplace {
    my $class = shift;
    my $context = context();

    my ( $sub, $expected, $build_test_obj ) = @_;

    subtest '! inplace' => sub {
        my $orig = $class->test_obj;
        my %data;
        for my $p ( 'p1', 'p2' ) {
            $data{$p} = wrap_hash( {
                    refaddr => refaddr( $orig->$p->get_dataref ),
                    copy    => $orig->$p->copy,
                },
            );
        }

        my $new = $sub->( $orig );
        $class->test_not_inplace_flat_obj( $orig, $new, $expected, %data );
    };

    $context->release;
}

sub build_expected {
    my $class = shift;
    my %data = @_;

    $class->test_class_new(
        p1 => PDL->new( $data{p1} ),
        p2 => PDL->new( $data{p2} ),
    );
}

1;
