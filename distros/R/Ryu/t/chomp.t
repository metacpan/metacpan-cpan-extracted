use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use Ryu;

my $first = Ryu::Source->new;
my @actual;
$first->some(sub { $_ < 0 })->each(sub {
	push @actual, $_;
});
$first->emit($_) for 2,8,3,-1,5;
$first->finish;
cmp_deeply(\@actual, [ 1 ], 'some operation was performed');
done_testing;
