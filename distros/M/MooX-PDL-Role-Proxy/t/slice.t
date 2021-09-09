#! perl

use Test::Lib;
use Test2::V0;
use Test2::Tools::PDL;
use Scalar::Util qw[ refaddr ];

use My::Test::Role;
package Test {

    use Role::Tiny::With;
    use PDL::Lite;

    with My::Test::Role::Single();

    sub test_obj {
        my $class = shift;

        $class->test_class_new(
            p1 => PDL->new( [ 0,  1, 2, 3, 4, 5, 7 ] ),
            p2 => PDL->new( [ -1, 1, 2, 3, 4, 5, 6 ] ),
        );

    }
}

Test->test(
    "[2,6]",
    sub { $_[0]->slice( [ 2, 6 ] ) },
    p1 => [ 2, 3, 4, 5, 7 ],
    p2 => [ 2, 3, 4, 5, 6 ],
);


done_testing;
