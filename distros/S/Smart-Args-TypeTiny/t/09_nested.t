use Test2::V0;
use Types::Standard -all;
use Smart::Args::TypeTiny;

sub foo1 {
    args my $bar => 'Num';
    foo2(boss => $bar);
}

sub foo2 {
    args my $boss => 'Int';
    return $boss * 3;
}

like dies { foo1(bar => 3.14) }, qr/@{[ quotemeta(__FILE__) ]}/;

done_testing;
