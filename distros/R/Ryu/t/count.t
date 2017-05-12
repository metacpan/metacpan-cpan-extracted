use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use Ryu;

my $first = Ryu::Source->new;
my @actual;
$first->count->each(sub {
	push @actual, $_;
});
$first->emit($_) for qw(a b e d c);
$first->finish;
cmp_deeply(\@actual, [ 5 ], 'count operation was performed');
done_testing;
