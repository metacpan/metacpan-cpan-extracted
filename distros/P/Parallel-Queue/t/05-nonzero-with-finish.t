########################################################################
# test job failure
########################################################################

use v5.10;
use strict;

use Test::More;

use Parallel::Queue qw( finish );

# depending on intra-job timing, there may be 
# one or two items left in @pass1 after the 
# queue is run once.

my @queue =
(
    sub {  0 },
    sub {  0 },

    sub {  1 },  # non-zero exit ignored via finish.

    sub {  0 },
    sub {  0 },
);

my @pass1   = runqueue 1, @queue;

my $count   = @pass1;

ok ! $count, "Zero ($count) jobs remaining?";

done_testing;

__END__
