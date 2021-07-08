#! perl

use Test::Lib;
use Test2::V0;
use Test2::Tools::PDL;

use Scalar::Util qw[ refaddr ];


package ClassHandles {

    use Moo;
    extends 'My::Class';
    has '+p1' => (
        is      => 'rwp',
        handles => ['qsorti'],
    );
}


package Test {

    use Test2::V0;
    use Role::Tiny::With;
    use PDL::Lite;

    with 'My::Test::Role::Single';

    our $p = PDL->random( 5 )->qsorti;

    sub test_class { 'ClassHandles' }

    sub test_obj {
        my $class = shift;

        $class->test_class_new(
            p1 => $p,
            p2 => PDL->sequence( 5 ),
        );

    }
}

Test->test(
    "qsort",
    sub { $_[0]->qsort },
    p1 => [ 0, 1, 2, 3, 4 ],
    p2 => PDL->sequence( 5 )->index( $Test::p->qsorti ),
);

Test->test(
    "qsort_on",
    sub { $_[0]->qsort_on( $Test::p ) },
    p1 => [ 0, 1, 2, 3, 4 ],
    p2 => PDL->sequence( 5 )->index( $Test::p->qsorti ),
);


my $obj = My::Class->new();
like(
    dies { $obj->qsort },
    qr/can't locate object method.*qsorti/i,
    "class doesn't handle qsorti"
);


done_testing;
