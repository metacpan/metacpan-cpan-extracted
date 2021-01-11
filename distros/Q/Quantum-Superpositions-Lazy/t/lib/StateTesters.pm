package StateTesters;

use v5.28;
use warnings;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use Exporter qw(import);
use Test::More;

our @EXPORT = qw(
	check_probability
	test_states
);

sub check_probability
{
	my ($state, $prob) = @_;

	# we'll be comparing with three digit precision, so add those in case they're not there
	my $state_weight = $state->weight;

	if ($state_weight =~ m{ \A (\d+) \. (\d+) \z }x) {
		$state_weight = "$1." . substr "${2}000", 0, 3;
	}
	else {
		$state_weight .= ".000";
	}

	is substr($state_weight, 0, length $prob), $prob, "state probability ok";
}

sub test_states
{
	my ($wanted, $states) = @_;

	is scalar @$states, scalar keys %$wanted, "states count ok";
	foreach my $state (@$states) {
		my $prob = $wanted->{$state->value};
		ok defined $prob, "state value ok";
		check_probability($state, $prob);
	}
}

1;
