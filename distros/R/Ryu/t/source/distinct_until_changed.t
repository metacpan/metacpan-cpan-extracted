use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use Ryu;

my $first = Ryu::Source->new;
my @actual;
$first->distinct_until_changed->each(sub {
    push @actual, $_;
});
$first->emit($_) for 1,2,undef,undef,3,undef,4,undef,5,6,undef,undef,8,8,8,undef,8,7;
cmp_deeply(\@actual, [ 1,2,undef,3,undef,4,undef,5,6,undef,8,undef,8,7 ], 'distinct_until_changed operation was performed');
done_testing;

