use Test2::V0;
use Smart::Args::TypeTiny;
use Mouse;
use Mouse::Util::TypeConstraints;

subtype 'PositiveInt',
    as 'Int',
    where { $_ > 0 },
    message { 'Must be greater than zero' };

{
    package Foo;
    sub new { bless {}, shift }
}

sub foo {
    args my $int => {isa => 'Int'};
}

sub bar {
    args my $positive_int => {isa => 'PositiveInt'};
}

sub baz {
    args my $foo => {isa => 'Foo'};
}

ok lives { foo(int => 1) };
like dies { foo(int => 'one') }, qr/Type check failed in binding to parameter '\$int'; Value "one" did not pass type constraint "Int"/;

ok lives { bar(positive_int => 1) };
like dies { bar(positive_int => 0) }, qr/Type check failed in binding to parameter '\$positive_int'; Must be greater than zero/;

ok lives { baz(foo => Foo->new) };
like dies { baz(foo => undef) }, qr/Type check failed in binding to parameter '\$foo'; Undef did not pass type constraint \(not isa Foo\)/;

done_testing;
