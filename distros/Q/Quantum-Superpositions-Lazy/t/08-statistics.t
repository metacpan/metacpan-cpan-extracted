use v5.24; use warnings;
use Test::More;
use Quantum::Superpositions::Lazy;
use Data::Dumper;
use lib 't/lib';
use StateTesters;

##############################################################################
# This is a test of all statistic metrics available in the module based on a
# trivial data set. We use strings and compare the float values up to a
# precision given in the string
##############################################################################

my $case1 = superpos([1, 1], [2, 2], [3, 3]);
my $case2 = superpos([0.5, 100], [0.3, 200], [0.2, 300]);

# values for this should be:
# [0.5, 100], [0.3, 200], [0.2, 300]
# [1, 200], [0.6, 400], [0.4, 600]
# [1.5, 300], [0.9, 600], [0.6, 900]
#
# after merging:
# [0.5, 100], [1.3, 200], [1.7, 300]
# [0.6, 400], [1.3, 600], [0.6, 900]
#
# total probability: 1 * 6 = 6
my $case_comp = $case2 * $case1;

isa_ok $case1->stats, "Quantum::Superpositions::Lazy::Statistics";

MOST_PROBABLE: {
	my $items = $case_comp->stats->most_probable;
	my %wanted = (
		# 1.7 / 6 = 0.283333
		300 => "0.283",
	);

	test_states(\%wanted, $items->states);
}

LEAST_PROBABLE: {
	my $items = $case_comp->stats->least_probable;
	my %wanted = (
		# 0.5 / 6 = 0.083333
		100 => "0.083",
	);

	test_states(\%wanted, $items->states);
}

MANY_PROBABLE: {
	my $many_case = superpos([0.25, 1], [0.5, 2], [0.25, 3]) * superpos(3);
	my %wanted = (
		3 => "0.250",
		9 => "0.250",
	);

	my $items = $many_case->stats->least_probable;
	test_states(\%wanted, $items->states);
}

MEDIAN: {
	my $item = $case_comp->stats->median;

	# 300 is the mean element for the set because its weight is
	# dividing the sorted set in the middle:
	# 0.5 + 1.3 = 1.8, is less than 3
	# 0.6 + 1.3 + 0.6 = 2.5, is also less than 3
	is $item, 300, "median ok";

	$item = $case1->stats->median;
	# Here the median should be 2, because two elements will meet
	# the condition, and we choose the one with less weight
	is $item, 2, "median special case ok";

	$item = $case1->stats->median_num;
	# Here the median should be
	# (2 * 2 + 3 * 3) / 5.0 = 2.6
	# because in median_num we create a weighted mean of the values
	is $item, 2.6, "averaged median ok";
}

MEAN: {
	my $item = $case_comp->stats->mean;

	# The weighted mean should be
	# (100 * 0.5 + 200 * 1.3 + 300 * 1.7 + 400 * 0.6 + 600 * 1.3 + 900 * 0.6) / 6
	# which is 396.666667
	is substr($item, 0, 6), 396.66, "mean ok";
	is $case_comp->stats->expected_value, $item, "expected value ok";
}

VARIANCE: {
	my $item = $case_comp->stats->variance;

	# variance should be E(X²) - E(X)², so:
	# (10000 * 0.5 + 40000 * 1.3 + 90000 * 1.7 + 160000 * 0.6 + 360000 * 1.3 + 810000 * 0.6) / 6.0 - 396.666667 * 396.666667
	# which is 52655.555291
	is substr($item, 0, 8), 52655.55, "variance ok";
}

STD_DEV: {
	my $item = $case_comp->stats->standard_deviation;

	# standard deviation should be a square root of deviation:
	# sqrt(52655.555291)
	# which is 229.467983
	is substr($item, 0, 6), 229.46, "standard deviation ok";

}

done_testing;

