# reported in https://rt.cpan.org/Public/Bug/Display.html?id=59573

use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    package Foo;

    use Moose;
    use MooseX::ClassAttribute;

    class_has attr => (
        is      => 'bare',
        isa     => 'HashRef[Str]',
        lazy    => 1,
        default => sub { {} },
        traits  => ['Hash'],
        handles => {
            has_attr => 'exists',
        },
    );
}

is(
    exception { Foo->has_attr('key') },
    undef,
    'Default builder in a native attribute trait is properly run when the attribute is defined with no standard accessors'
);

done_testing();
