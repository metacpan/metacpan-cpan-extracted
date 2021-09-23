package Stats::Hawking::HTRandom;

use Stats::Fermi::Boltzmann;

sub new {
	my ($class) = @_;
	my $self = {
		generator => Stats::Hawking::HawkingTemperature->new,
		boltzmannf => Stats::Fermi::Boltzmann->new,
	};

	$class = ref($class) || $class;

	bless $self, $class;
}

### random without Boltzmann, just that
sub random0 {
	my ($self, $solarmass_random) = shift;
	return $self->{generator}->funcall($solarmass_random);
}

### small random
sub random1 {
	my ($self) = shift;
	return $self->{generator}->funcall(rand);
}

### random with Hawking Temperature in a Boltzmann function, the real thing
sub random {
	my ($self) = shift;

	return $self->{boltzmannf}->funcall(rand, $self->random1(), rand);
}

1;
