package AlternativeStatistics;

use parent 'Quantum::Superpositions::Lazy::Statistics';

$Quantum::Superpositions::Lazy::Statistics::implementation = __PACKAGE__;

sub random_most_probable
{
	my ($self) = @_;
	return $self->most_probable->reset->collapse;
}

1;
