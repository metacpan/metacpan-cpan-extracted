use v5.24;
use warnings;
use Test::More;
use Quantum::Superpositions::Lazy qw(superpos fetch_matches one_state every_state);
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

subtest "complex comparison test" => sub {
	my $another_case = superpos(qw(tset tat est set tseeet));
	my $comp_sub = sub {
		$_[0] eq scalar reverse $_[1];
	};

	ok one_state { $case->compare($comp_sub, $another_case) };
	ok !every_state { $case->compare($comp_sub, $another_case) };
};

subtest "complex comparison test (negative)" => sub {
	my $another_case = superpos(qw(ssssss s));
	my $yet_another_case = superpos(qw(ssssss sssssssss));
	my $comp_sub = sub {
		length $_[0] ne length $_[1]
			&& length $_[0] ne length $_[2];
	};

	ok every_state { $case->compare($comp_sub, $another_case, $yet_another_case) };
};

done_testing;
