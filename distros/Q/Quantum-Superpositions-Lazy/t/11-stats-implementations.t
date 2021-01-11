use v5.28;
use warnings;
use Test::More;
use Quantum::Superpositions::Lazy;
use Data::Dumper;
use lib 't/lib';
use AlternativeStatistics;

##############################################################################
# tests if alternative implementations of statistics work as intended
##############################################################################

my $superpos = superpos(7);
my $stats = $superpos->stats;

isa_ok $stats, AlternativeStatistics::, 'implementation used ok';
can_ok $stats, 'random_most_probable';

is $stats->random_most_probable, 7, 'return value ok';

done_testing;
