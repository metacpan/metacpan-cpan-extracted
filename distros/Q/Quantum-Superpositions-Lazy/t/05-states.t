use v5.24;
use warnings;
use Test::More;
use Quantum::Superpositions::Lazy;
use Data::Dumper;
use lib 't/lib';
use StateTesters;

##############################################################################
# Tests on produced (eigen)states. A list of every possible outcome should
# be produced, along with their probabilities. Duplicated values should be
# merged where possible.
##############################################################################

my $pos = superpos(6, 5, 4);

KET: {
	my $ket = $pos->to_ket_notation;
	like $ket, qr/0.33+?|4/, "ket ok";
	like $ket, qr/0.33+?|5/, "ket ok";
	like $ket, qr/0.33+?|6/, "ket ok";
	like $ket, qr/\A.+?> \+ .+?> \+ .+?>\z/, "ket ok";
}

SIMPLE_TEST: {
	my %wanted = map { $_ => "1.000" } 6, 5, 4;
	my @states = $pos->states->@*;

	test_states(\%wanted, \@states);
}

TEST_PLUS_SCALAR: {
	my $comp = $pos * 2;
	my %wanted = map { $_ => "0.333" } 12, 10, 8;

	test_states(\%wanted, $comp->states);
}

TEST_PLUS_SUPERPOS: {
	my $comp = $pos * superpos(2, 3);
	my %wanted = (
		18 => "0.166",
		15 => "0.166",
		12 => "0.333",
		10 => "0.166",
		8 => "0.166",
	);

	test_states(\%wanted, $comp->states);
}

TEST_NESTED_IN_STATE: {
	my $complex_pos = superpos([6, $pos * superpos(2, 3)], [5, 2], [3, 3], [2, 18]);
	my %wanted = (
		18 => "3.000",
		15 => "1.000",
		12 => "2.000",
		10 => "1.000",
		8 => "1.000",
		2 => "5.000",
		3 => "3.000",
	);

	test_states(\%wanted, $complex_pos->states);
}

done_testing;
