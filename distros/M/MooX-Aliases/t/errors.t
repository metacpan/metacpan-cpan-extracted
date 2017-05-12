use strictures 1;
use Test::More;
use Test::Fatal;

{
    package Foo;
    use Moo;
    use MooX::Aliases;

    ::like( ::exception { alias foo => 'bar' }, qr/^Cannot find method bar to alias/,
        "aliasing a non-existent method gives an appropriate error");

    has foo => (
        is    => 'ro',
        alias => [qw(bar baz quux)],
    )
}

like( exception { Foo->new(bar => 1, baz => 2) },
          qr/^Conflicting init_args: \(bar, baz\)/,
          "conflicting init_args give an appropriate error");

done_testing;
