use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use Ryu;

my $first = Ryu::Source->new;
my @actual;
$first->distinct->each(sub {
	push @actual, $_;
});
$first->emit($_) for 1,2,undef,3,undef,1,2,1,1,1,2,1,5,6,undef,undef,8,8,8,undef,8,7;
cmp_deeply(\@actual, [ 1,2,undef,3,5,6,8,7 ], 'distinct operation was performed');
done_testing;

