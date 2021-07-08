#! perl

use Test::Lib;
use Test2::V0;
use Test2::Tools::PDL;

use Scalar::Util qw[ refaddr ];


package Test {

    use Role::Tiny::With;
    use PDL::Lite;

    with 'My::Test::Role::Single';

    sub test_obj {
        my $class = shift;

        $class->test_class_new(
            p1 => PDL->new( [ 0,  1, 2, 3, 4, 5, 7 ] ),
            p2 => PDL->new( [ -1, 1, 2, 3, 4, 5, 6 ] ),
        );

    }
}

Test->test(
    "clip_on (min,undef]",
    sub { $_[0]->clip_on( $_[0]->p1, 2, undef ) },
    p1 => [ 2, 3, 4, 5, 7 ],
    p2 => [ 2, 3, 4, 5, 6 ],
);

Test->test(
    "clip_on (min,max]",
    sub { $_[0]->clip_on( $_[0]->p1, 2, 5 ) },
    p1 => [ 2, 3, 4, ],
    p2 => [ 2, 3, 4, ],
);

Test->test(
    "clip_on (undef,max]",
    sub { $_[0]->clip_on( $_[0]->p1, undef, 5 ) },
    p1 => [ 0,  1, 2, 3, 4, ],
    p2 => [ -1, 1, 2, 3, 4, ],
);


done_testing;
