use strict;
use warnings;
use Test::More tests => 1+20;
BEGIN { use_ok('Statistics::Test::Sequence') };
use constant EPS => 1e-9;

foreach (1..10) {
    my $n = 10000*$_**2;
    my $f = Statistics::Test::Sequence::expected_frequency(1, $n);
    my $exp = ($n*5+1)/12;
    ok(about_equal($exp, $f), "Expect frequency for n=$n, k=1 ($exp == $f)");
}

foreach (1..10) {
    my $n = 10005*$_**2;
    my $f = Statistics::Test::Sequence::expected_frequency(2, $n);
    my $exp = ($n*11-14)/60;
    ok(about_equal($exp, $f), "Expect frequency for n=$n, k=2 ($exp == $f)");
}

sub about_equal {
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
