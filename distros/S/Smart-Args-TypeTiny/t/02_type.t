use Test2::V0;
use Types::Standard -all;
use Smart::Args::TypeTiny;

sub foo {
    args my $x => Int;
    return $x*2;
}

sub bar {
    args_pos my $x => Int;
    return $x*2;
}

sub baz {
    args_pos my $x => 'Int';
    return $x*2;
}

ok lives { foo(x => 3) }; # yutori is good
is foo(x => 3), 6;
like dies { foo(x => 3.14) }, qr/Type check failed in binding to parameter '\$x'; Value "3\.14" did not pass type constraint "Int"/;

ok lives { bar(3) }; # yutori is good
is bar(3), 6;
like dies { bar(3.14) }, qr/Type check failed in binding to parameter '\$x'; Value "3\.14" did not pass type constraint "Int"/;

ok lives { baz(3) }; # yutori is good
is baz(3), 6;
like dies { baz(3.14) }, qr/Type check failed in binding to parameter '\$x'; Value "3\.14" did not pass type constraint "Int"/;

done_testing;
