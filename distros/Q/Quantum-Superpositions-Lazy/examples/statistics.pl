use v5.28; use warnings;
use Test::More;
use Quantum::Superpositions::Lazy;

sub is_with_precision
{
	my ($num, $exp, $note) = @_;
	is sprintf("%.5f", $num), sprintf("%.5f", $exp), $note;
}

my $dataset =

	# numbers from 1 to 9, with weights from 9 to 1
	superpos(map { [$_, 10 - $_] } 1 .. 9)
	*

	# even numbers from 100 to 200, with weight from 1 to 25 to 1
	superpos(map { [25 - abs(25 - $_), 100 + $_ * 2] } 1 .. 49)
	;

my $stats = $dataset->stats;

note "most probable outcome: " . $stats->most_probable->to_ket_notation;
note "least probable outcome: " . $stats->least_probable->to_ket_notation;
note "median: " . $stats->median;
note "expected value: " . $stats->expected_value . " ± " . $stats->standard_deviation;
note "random roll: " . $dataset->collapse;

is_with_precision $stats->median, 360, "median ok";
is_with_precision $stats->mean, 550, "mean ok";
is_with_precision $stats->most_probable->states->[0]->weight, "0.008", "most probable weight ok";

done_testing;

__END__

=pod

This example showcases the usage of statistical data that can be extracted from
superpositions with the C<< $superpos->stats >> method.
