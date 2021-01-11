use v5.28;
use warnings;
use Test::More;
use Quantum::Superpositions::Lazy qw(with_sources);
use Data::Dumper;

##############################################################################
# A test for the calculation sourcing - whether it works, and whether it only
# works when invoked with_sources
##############################################################################

my $case1 = superpos(2, 3, 10);
my $case2 = superpos(2, 10, 20);

my %sources = (
	"8" => [[10, 2]],
	"1" => [[3, 2]],
	"0" => [[2, 2], [10, 10]],
	"-7" => [[3, 10]],
	"-8" => [[2, 10]],
	"-10" => [[10, 20]],
	"-17" => [[3, 20]],
	"-18" => [[2, 20]],
);

my $computation = $case1 - $case2;
my $states = with_sources { $computation->states };

foreach my $state ($states->@*) {
	isa_ok $state, "Quantum::Superpositions::Lazy::ComputedState";
	is_deeply [sort { $a->[0] <=> $b->[0] } @{$state->source}], $sources{$state->value},
		"state source ok";
	is $state->operation->sign, "-", "state sign ok";
}

$computation->clear_states;

foreach my $state ($computation->states->@*) {
	isa_ok $state, "Quantum::Superpositions::Lazy::State";
}

done_testing;
