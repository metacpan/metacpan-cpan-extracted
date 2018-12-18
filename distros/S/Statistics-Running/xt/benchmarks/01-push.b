#!perl -T
use 5.006;

use strict;
use warnings;

use Statistics::Running;
use Test::More;
use Benchmark qw/timethese cmpthese :hireswallclock/;

use constant VERBOSE => 1; # prints out several junk
my $num_repeats = 1000;
my $NUM_DATAPOINTS = 1000;

print "$0 : benchmarks...\n";

my $RU1 = Statistics::Running->new();

# shamelessly ripped off App::Benchmark
cmpthese(timethese($num_repeats, {
	'Statistics::Running : add '.$NUM_DATAPOINTS.' data points, repeats '.$num_repeats.':' => \&runme
}));
plan tests => 1;
pass('benchmark : '.__FILE__);

sub     runme {
	for(1..$NUM_DATAPOINTS){
		$RU1->add(rand(10));
	}
}
1;
__END__
