use strict;
use warnings;
use Test::More 0.88;
use Test::Fatal;

{
    package Foo;
    use Moose;
    use MooseX::LazyRequire;

    has bar => (
        is            => 'ro',
        lazy_required => 1,
    );
}

{
    is(
        exception { Foo->new },
        undef,
        'lazy_required attrs are not required until first accessed',
    );

    like(
        exception { Foo->new->bar },
        qr/Attribute 'bar' must be provided/,
        'lazy_required value was not provided',
    );
}

{
    package Bar;
    use Moose;
    use MooseX::LazyRequire;

    has foo => (
        is            => 'rw',
        lazy_required => 1,
    );

    has baz => (
        is      => 'ro',
        lazy    => 1,
        builder => '_build_baz',
    );

    sub _build_baz { shift->foo + 1 }
}

{
    my $bar = Bar->new;

    like(
        exception { $bar->baz },
        qr/Attribute 'foo' must be provided/,
        'lazy_required dependency is not satisfied',
    );

    $bar->foo(42);

    my $baz;
    is(
        exception { $baz = $bar->baz },
        undef,
        'lazy_required dependency is satisfied',
    );

    is($baz, 43, 'builder uses correct value');
}

SKIP:
{
    skip 'These tests require Moose 1.9900+', 3
        unless $Moose::VERSION >= 1.9900;

{
    package Role;
    use Moose::Role;
    use MooseX::LazyRequire;

    has foo => (
        is            => 'rw',
        lazy_required => 1,
    );

    has baz => (
        is      => 'ro',
        lazy    => 1,
        builder => '_build_baz',
    );

    sub _build_baz { shift->foo + 1 }
}

{
    package Quux;
    use Moose;
    with 'Role';
}

{
    my $bar = Quux->new;

    like(
        exception { $bar->baz },
        qr/Attribute 'foo' must be provided/,
        'lazy_required dependency is not satisfied (in a role)',
    );

    $bar->foo(42);

    my $baz;
    is(
        exception { $baz = $bar->baz },
        undef,
        'lazy_required dependency is satisfied (in a role)',
    );

    is($baz, 43, 'builder uses correct value (in a role)');
}
}

done_testing;
