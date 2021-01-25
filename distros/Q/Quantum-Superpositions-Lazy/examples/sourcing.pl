use v5.28;
use warnings;
use Test::More;
use Quantum::Superpositions::Lazy qw(superpos fetch_matches with_sources);

sub power_sources
{
	my ($number) = @_;

	# produce all the possible bases end exponents
	my $possible_bases = superpos(2 .. sqrt $number);
	my $possible_exponents = superpos(2 .. sqrt $number);

	# produce all possible powers
	my $possible_powers = $possible_bases**$possible_exponents;

	# for every state, get those that match a condition
	# (any possible power that equals the number)
	return fetch_matches {
		with_sources { $possible_powers == $number }
	};
}

my %numbers = (

	# number => [base, exponent]
	65536 => [[2, 16], [4, 8], [16, 4], [256, 2]],
	9 => [[3, 2]],
	81 => [[3, 4], [9, 2]],
	3 => [],
);

while (my ($number, $power) = each %numbers) {

	# this will be a superposition of all valid powers
	my $power_superposition = power_sources $number;

	# there should be 1 or 0 resulting states
	my $state = $power_superposition->states->[0];

	if (!defined $state) {
		is scalar $power->@*, 0;
	}
	else {
		my @sources = $state->source->@*;
		is scalar @sources, scalar $power->@*;

		# did we succeed?
		FACTOR:
		foreach my $factor ($power->@*) {
			my ($base, $exponent) = $factor->@*;

			foreach my $source (@sources) {
				next FACTOR
					if $source->[0] eq $base && $source->[1] eq $exponent;
			}
			fail;
		}
	}
}

done_testing;

__END__

=pod

The module allows getting the sources of computations right from the computed
state with some extra hassle.  This example shows how to get all possible
powers that represent a given number, like for example 4 = 2², 16 = 2⁴ | 4²
