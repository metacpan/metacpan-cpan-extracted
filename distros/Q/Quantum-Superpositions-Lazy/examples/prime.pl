use v5.28; use warnings;
use Test::More;
use Quantum::Superpositions::Lazy qw(every_state);

sub is_prime
{
	my ($number) = @_;

	# produce all the possible factors up to square root
	my $possible_factors = superpos(2 .. sqrt $number);

	# for every state, check that there's no division remainder
	return every_state { ($number % $possible_factors) != 0 };
}

my %numbers = (

	# number => is_prime?
	78 => 0,
	79 => 1,
	236116321 => 0,
);

while (my ($number, $is_prime) = each %numbers) {

	my $prime = is_prime $number;

	# did we succeed?
	is $prime, !!$is_prime, "$number result ok - " . ($is_prime ? "is" : "isnt") . " prime";
}

done_testing;

__END__

=pod

Checking if the number is a prime is probably the most common example of
quantum computations.
