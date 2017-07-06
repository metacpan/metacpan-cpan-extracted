use 5.012;
use warnings;

use Test::More;

use Perl6::Controls;

my @seq = (1,1,2,3,5);

while (my $n = shift @seq) {
    ok $n > 0;
}

@seq = (1,1,2,3,5);

while (shift @seq) -> $n {
    ok $n > 0;
}

my $n = 2;
ok 1 until $n-- == 0;

done_testing();

