use v5.24;
use warnings;
use Test::More;
use Quantum::Superpositions::Lazy qw(superpos fetch_matches every_state);
use Data::Dumper;
use lib 't/lib';
use StateTesters;

##############################################################################
# This test is asserting that comparing superpositions in fetch_matches block
# is yielding a new superposition with their states copied together with
# weights
##############################################################################

my $pos1 = superpos(1, 2, [8, 3], [7, 4], 100, [2, 101]);
my $pos2 = superpos(3, [2, 4], 5, 100);
my $pos3 = superpos(0, 1, 2);

subtest 'contains ok' => sub {
	my $pos = fetch_matches { $pos1 == $pos2 };
	my %wanted = (
		3 => "8.000",
		4 => "7.000",
		100 => "1.000",
	);

	isa_ok $pos, "Quantum::Superpositions::Lazy::Superposition";
	test_states(\%wanted, $pos->states);
};

subtest 'superpos every state contains ok' => sub {
	my $pos = fetch_matches {
		every_state { $pos1 > $pos3 }
	};
	my %wanted = (
		3 => "8.000",
		4 => "7.000",
		100 => "1.000",
		101 => "2.000",
	);

	isa_ok $pos, "Quantum::Superpositions::Lazy::Superposition";
	test_states(\%wanted, $pos->states);
};

subtest 'scalar contained ok' => sub {
	my $pos = fetch_matches { 4 == $pos2 };
	my %wanted = (
		4 => "1.000",
	);

	isa_ok $pos, "Quantum::Superpositions::Lazy::Superposition";
	test_states(\%wanted, $pos->states);
};

subtest 'superpos not equal ok' => sub {
	my $pos = fetch_matches { $pos1 != $pos2 };
	my %wanted = (
		1 => "1.000",
		2 => "1.000",
		3 => "8.000",
		4 => "7.000",
		100 => "1.000",
		101 => "2.000",
	);

	isa_ok $pos, "Quantum::Superpositions::Lazy::Superposition";
	test_states(\%wanted, $pos->states);
};

subtest 'superpos every state not equal ok' => sub {
	my $pos = fetch_matches {
		every_state { $pos1 != $pos2 }
	};
	my %wanted = (
		1 => "1.000",
		2 => "1.000",
		101 => "2.000",
	);

	isa_ok $pos, "Quantum::Superpositions::Lazy::Superposition";
	test_states(\%wanted, $pos->states);
};

done_testing;
