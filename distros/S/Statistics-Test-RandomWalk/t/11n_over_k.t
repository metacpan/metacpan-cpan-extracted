use strict;
use warnings;
use Test::More tests => 231;
BEGIN { use_ok('Statistics::Test::RandomWalk') };

use Math::BigFloat;
use Statistics::Test::Sequence;

sub n_over_k {
    my $n = Math::BigFloat->new(shift);
    my $k = Math::BigFloat->new(shift);
    
    return(
        Statistics::Test::Sequence::faculty($n)
        / (
            Statistics::Test::Sequence::faculty($k)
            * Statistics::Test::Sequence::faculty($n-$k)
        )
    );
}

foreach my $n ( 1..20 ) {
    foreach my $k (0..$n) {
        my $str = Statistics::Test::RandomWalk::n_over_k($n, $k);
        my $test = n_over_k($n, $k);
        ok(
            $str == $test,
            "n_over_k($n, $k) = $str | $test"
        );
    }
}

