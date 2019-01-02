use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use Ryu;

my $first = Ryu::Source->new;
my $stats;
$first->statistics->each(sub {
    isa_ok($_, 'HASH');
    is($stats, undef, 'have no stats yet');
    $stats = $_;
});
$first->emit($_) for 1..9;
$first->finish;
cmp_deeply($stats, {
    min   => 1,
    max   => 9,
    mean  => 5,
    count => 9,
    sum   => 45,
}, 'statistics operation was performed');
done_testing;
