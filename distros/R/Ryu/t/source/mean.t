use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use Ryu;

my $first = Ryu::Source->new;
my @actual;
$first->mean->each(sub {
    push @actual, $_;
});
$first->emit($_) for 2,4,2,4;
$first->finish;
cmp_deeply(\@actual, [ 3 ], 'mean operation was performed');
done_testing;
