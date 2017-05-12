use strict;
use warnings;

use Test::More;
use Net::Async::Statsd::Client;

use constant ITERATIONS => 10_000;

# Make this test more consistent (for the given platform/software combination, at least)
srand(123);
my $client = Net::Async::Statsd::Client->new;

for my $k (0.5, 0.25, 0.1, 0.9, 0.01) {
	my $count = 0;
	$client->sample($k) && ++$count for 1..ITERATIONS;
	note "$k: $count out of " . ITERATIONS . " => " . ($count / ITERATIONS);
	cmp_ok(abs((($count / ITERATIONS) - $k) / $k), '<', 0.05, 'sample count is within 5%')
		or note abs((($count / ITERATIONS) - $k) / $k);
}
{ # Special-case 1, we should always give 100% for this value
	my $count = 0;
	$client->sample(1) && ++$count for 1..ITERATIONS;
	is($count, ITERATIONS, "sample rate of 1 never drops samples");
}
done_testing;

