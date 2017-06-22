use 5.014;
use warnings;

use Test::More;

use Perl6::Controls;

my %twice = (1=>2, 3=>6, 7=>14);

for (keys %twice) {
    ok exists $twice{$_};
}

for my $elem (keys %twice) {
    ok exists $twice{$elem};
}

for (%twice) -> $key, $value {
    is $value, $twice{$key};
}

for ( ^10 ) -> $n {
    ok 0 <= $n && $n < 10;
}

ok 1 foreach 1..2;

done_testing();
