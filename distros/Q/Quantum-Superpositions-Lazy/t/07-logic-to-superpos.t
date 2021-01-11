use v5.28;
use warnings;
use Test::More;
use Quantum::Superpositions::Lazy qw(fetch_matches);
use Data::Dumper;
use lib 't/lib';
use StateTesters;

##############################################################################
# This test is asserting that comparing superpositions in fetch_matches block
# is yielding a new superposition with their states copied together with
# weights
##############################################################################

my $pos1 = superpos(1, 2, [8, 3], [7, 4], 100);
my $pos2 = superpos(3, [2, 4], 5, 100);

CONTAINS: {
	my $pos3 = fetch_matches { $pos1 == $pos2 };
	my %wanted = (
		3 => "8.000",
		4 => "7.000",
		100 => "1.000",
	);

	isa_ok $pos3, "Quantum::Superpositions::Lazy::Superposition";
	test_states(\%wanted, $pos3->states);
}

SCALAR_CONTAINED: {
	my $pos3 = fetch_matches { 4 == $pos2 };
	my %wanted = (
		4 => "1.000",
	);

	isa_ok $pos3, "Quantum::Superpositions::Lazy::Superposition";
	test_states(\%wanted, $pos3->states);
}

done_testing;
