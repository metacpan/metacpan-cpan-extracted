use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use Ryu;

my $first = Ryu::Source->new;
my @actual;
$first->sum->each(sub {
	push @actual, $_;
});
$first->emit($_) for 1..5;
$first->finish;
cmp_deeply(\@actual, [ 15 ], 'sum operation was performed');
done_testing;

