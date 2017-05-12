use strict;
use warnings;

use Test::More 0.88;
use Test::Moose qw( with_immutable );
use Test::Fatal;

{
    package Foo;
    use Moose;
    use MooseX::SlurpyConstructor;

    has slurpy => ( is => 'ro', slurpy => 1);
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
