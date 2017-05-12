# Reported as https://rt.cpan.org/Public/Bug/Display.html?id=59663

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Test::Requires {
    'MooseX::Role::Strict' => 0.01,
};

{
    package Role;

    use MooseX::Role::Strict;
    use MooseX::ClassAttribute;

    class_has attr => (
        traits  => ['Hash'],
        is      => 'ro',
        isa     => 'HashRef[Str]',
        lazy    => 1,
        default => sub { {} },
        handles => {
            has_attr => 'exists',
        },
    );

    sub normal_method {
        Test::More::pass('a regular method from the role is composed');
    }

}

{
    package Foo;
    use Moose;

    with 'Role';
}

Foo->normal_method();

{
    local $TODO = 'This test does not yet pass';

    is(
        exception { Foo->has_attr('key') }, undef,
        'Delegated method from native attribute trait is properly composed from a strict role'
    );
}

done_testing();
