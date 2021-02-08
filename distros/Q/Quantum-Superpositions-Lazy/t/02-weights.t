use v5.24;
use warnings;
use Test::More;
use Mock::Sub;
use Quantum::Superpositions::Lazy::Util;

my $rand;

BEGIN {
	$rand = Mock::Sub->new->mock("Quantum::Superpositions::Lazy::Util::get_rand");
	eval "use Quantum::Superpositions::Lazy";
}

##############################################################################
# This test tries to check if the weights specified at the creation of a
# superposition are used in the collapsing of the quantum state.
##############################################################################

my $superpos = superpos([1 => 1], [3 => 2]);

for my $state ($superpos->_states->@*) {
	if ($state->value eq 1) {
		is $state->weight, 1, "weight ok";
	}
	elsif ($state->value eq 2) {
		is $state->weight, 3, "weight ok";
	}
	else {
		fail "unexpected value in quantum states";
	}
}

for my $num (0 .. 10) {

	# add just a little to the denominator to avoid returning 1
	$rand->return_value($num / (10.000000001));
	my $collapsed = $superpos->collapse;
	note Quantum::Superpositions::Lazy::Util::get_rand . " - $collapsed";

	is $collapsed, ($num <= 2 ? 1 : 2), "value weight ok";
	$superpos->reset;
}

my $pos_with_zero_weights = superpos([0 => 0], [1 => 1], [0 => 2]);
$rand->return_value(0);
my $collapsed = $pos_with_zero_weights->collapse;
is $collapsed, 1, 'collapse with zero weight ok';

done_testing;
