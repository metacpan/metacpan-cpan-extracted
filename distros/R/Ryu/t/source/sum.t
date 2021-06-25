use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use Ryu;

my $first = Ryu::Source->new;
my @actual;
my $sum = $first->sum;
$sum->each(sub {
    push @actual, $_;
});
$first->emit($_) for 1..5;
$first->finish;
cmp_deeply(\@actual, [ 15 ], 'sum operation was performed');
ok($sum->completed->is_done, 'marked as done');
done_testing;

