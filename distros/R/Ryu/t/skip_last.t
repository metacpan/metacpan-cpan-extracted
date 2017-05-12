use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use Ryu;

my $first = Ryu::Source->new;
my @actual;
$first->skip_last(2)->each(sub {
	push @actual, $_;
});
$first->emit($_) for 1..5;
cmp_deeply(\@actual, [ 1..3 ], 'skip_last operation was performed');
done_testing;
