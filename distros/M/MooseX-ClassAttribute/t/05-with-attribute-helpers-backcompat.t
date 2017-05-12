use strict;
use warnings;

use Test::More;

use Test::Requires 0.05 {
    'MooseX::AttributeHelpers' => 0.23,
};

{
    package MyClass;

    use Moose;
    use MooseX::ClassAttribute;
    use MooseX::AttributeHelpers;

    class_has counter => (
        metaclass => 'Counter',
        is        => 'ro',
        provides  => {
            inc => 'inc_counter',
        },
    );
}

is( MyClass->counter(), 0 );

MyClass->inc_counter();
is( MyClass->counter(), 1 );

done_testing();
