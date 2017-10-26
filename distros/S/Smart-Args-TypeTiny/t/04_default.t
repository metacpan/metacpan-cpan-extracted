use Test2::V0;
use Types::Standard -all;
use Smart::Args::TypeTiny;

sub foo {
    args my $p => { isa => Int, default => 99 };
    return $p;
}

sub bar {
    args_pos my $p => { isa => Int, default => 99 };
    return $p;
}

sub baz1 {
    args_pos my $p => { isa => Int, default => sub { 99 } };
    return $p;
}

sub baz2 {
    args_pos my $p => { isa => Int, default => sub { my @a = ('a', 'b'); @a } };
    return $p;
}

sub baz3 {
    args_pos my $p => { isa => Int, default => sub { 'A' } };
    return $p;
}

is foo(), 99;
is foo(p => 0), 0;

is bar(), 99;
is bar(0), 0;

is baz1(), 99;
is baz2(), 2, 'return as scalar context';
like dies { baz3() }, qr/Type check failed in binding to parameter '\$p'; Value "A" did not pass type constraint "Int"/;

done_testing;
