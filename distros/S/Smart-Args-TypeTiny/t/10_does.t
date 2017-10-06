use Test2::V0;
use Types::Standard -all;
use Smart::Args::TypeTiny;

{
    package Foo;
    use Moo::Role;

    package Bar;
    use Moo;
    with 'Foo';

    package Baz;
    use Moo;
}

sub foo {
    args my $foo => { does => 'Foo' };
}

ok lives { foo(foo => Bar->new) };

like dies {
    foo(foo => Baz->new());
}, qr/Type check failed in binding to parameter '\$foo'; Reference bless\( \{\}, 'Baz' \) did not pass type constraint \(not DOES Foo\)/;

done_testing;
