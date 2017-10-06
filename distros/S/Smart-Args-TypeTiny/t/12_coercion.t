use Test2::V0;
use Types::Standard -all;
use Smart::Args::TypeTiny;

my $MyHashRef = HashRef->plus_coercions(ArrayRef, sub { +{ @{$_} } });

sub foo {
    args my $h => $MyHashRef;
    return $h;
}

is foo( h => { foo => 42 } ), { foo => 42 };
is foo( h => [ foo => 42 ] ), { foo => 42 };

like dies {
    foo(h => 42);
}, qr/Type check failed in binding to parameter '\$h'; Value "42" did not pass type constraint "HashRef"/;

done_testing;
