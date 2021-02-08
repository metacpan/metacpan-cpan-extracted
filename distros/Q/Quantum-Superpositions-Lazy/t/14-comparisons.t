use v5.24;
use warnings;
use Test::More;
use Quantum::Superpositions::Lazy qw(superpos fetch_matches);
use lib 't/lib';
use StateTesters;

##############################################################################
# A check of transformations - whether it morphs all the states.
##############################################################################

my $case = superpos(qw(test teest tst eeest));
my $matched = fetch_matches {
	$case->compare(sub { /^te+st$/ })
};

my %wanted = (
	test => "1.000",
	teest => "1.000",
);

test_states(\%wanted, $matched->states);

done_testing;
