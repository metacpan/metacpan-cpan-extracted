use v5.24;
use warnings;
use Test::More;
use Q::S::L;

##############################################################################
# This test checks if empty superpositions still behave nicely
##############################################################################

my $empty = superpos();

is $empty->weight_sum, 0, 'weight sum ok';
is $empty->stats->mean, undef, 'mean ok';
is $empty->stats->median, undef, 'median ok';

ok !(5 eq $empty), 'logical operation ok';

my $still_empty = 5 + $empty;

is scalar $still_empty->states->@*, 0, 'computional operation ok';

done_testing;
