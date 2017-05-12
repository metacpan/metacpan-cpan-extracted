use strict;
use warnings;
use Smart::Args;
use Test::More;
use t::Util;

{
    package Foo;
    use Mouse::Role;

    package Bar;
    use Mouse;
    with 'Foo';

    package Baz;
    use Mouse;
}

ok foo(foo => Bar->new);

throws_ok {
    foo(foo => Baz->new());
} qr/Validation failed for 'Foo' with value Baz/;

done_testing;

exit;

sub foo {
    args my $foo => { does => 'Foo' };
    1
}

