use strict;
use warnings;
use Test::More;

# A suite of tests to ensure that the binning behavior works as expected.

use PDL::Graphics::Prima;
use PDL;

# Test edge cases for linear and logarithmic scaling. Note that I don't
# need to worry about sending the dataset object because these routines
# don't rely on the dataset object.

for (-1, 0, 1) {
	# One of the bins will have all of them
	my ($xs, $ys) = bt::Linear(normalize => 0)->(ones(20) * $_);
	is(sum($ys == 20), 1, "For 20 identical entries of $_ with linear binning, we have one nonzero bin")
		or diag("ys were $ys");
	ok($xs->at(0) < $xs->at(-1), "For 20 identical entries of $_ and linear binning, x-bins are properly ordered")
		or diag("xs were $xs");
}
for (0.5, 1, 2) {
	my ($xs, $ys) = bt::Log(normalize => 0)->(ones(20) * $_);
	is(sum($ys == 20), 1, "For 20 identical entries of $_ with log binning, we have one nonzero bin")
		or diag("ys were $ys");
	ok($xs->at(0) < $xs->at(-1), "For 20 identical entries of $_ with log binning, x-bins are properly ordered")
		or diag("xs were $xs");
}

done_testing();
