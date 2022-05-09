use v5.24;
use warnings;
use Test::More;
use Q::S::L qw(superpos fetch_matches);

sub get_factors
{
	my ($number) = @_;

	# produce all the possible factors
	my $possible_factors = superpos(2 .. $number / 2);

	# for every state, get those that match a condition
	# (any possible factor that is present after the number is divided by any other one)
	return fetch_matches { $possible_factors == ($number / $possible_factors) };
}

my %numbers = (

	# number => factors
	78 => [2, 3, 6, 13, 26, 39],
	37 => [],
	21 => [3, 7],
);

while (my ($number, $factors) = each %numbers) {

	# this will be a superposition of all valid factors
	my $factors_superposition = get_factors $number;

	# did we succeed?
	foreach my $factor (@$factors) {
		ok $factors_superposition == $factor, "factor $factor found ok";
	}
	is scalar $factors_superposition->states->@*, @$factors, "factors count ok";
}

done_testing;

__END__

=pod

This example shows a straightforward way obtain all factors of a given number
using superpositions.  The C<meets_condition> block allows the C<==> operator
to fetch the factors that meet a condition, instead of returning a boolean.
