use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use Ryu;

my $first = Ryu::Source->new;
my @actual;
$first->min->each(sub {
	push @actual, $_;
});
$first->emit($_) for 5,2,8,-2,3,0,-100,4;;
$first->finish;
cmp_deeply(\@actual, [ -100 ], 'min operation was performed');
done_testing;

