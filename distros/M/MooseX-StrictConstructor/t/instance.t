## no critic (Moose::RequireMakeImmutable, Moose::RequireCleanNamespace)
use strict;
use warnings;

use Test::More;
use Test::Moose qw( with_immutable );
use Test::Fatal;

{
    package Foo;
    use Moose;
    use MooseX::StrictConstructor;
}

with_immutable {
    is(
        exception { Foo->new( __INSTANCE__ => Foo->new ) },
        undef,
        '__INSTANCE__ is ignored when passed to ->new',
    );

    is(
        exception { Foo->meta->new_object( __INSTANCE__ => Foo->new ) },
        undef,
        '__INSTANCE__ is ignored when passed to ->new_object',
    );
}
'Foo';

done_testing();
