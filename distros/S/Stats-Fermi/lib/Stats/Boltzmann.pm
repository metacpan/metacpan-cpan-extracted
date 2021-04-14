package Stats::Fermi::Boltzmann;

sub new {
	my ($class) = @_;
	my $self = {
		PI => 3.14152,
		k => 1.380649 * pow(10,-23), 
	};

	$class = ref($class) || $class;

	bless $self, $class;
}

sub funcall {

	my ($self, $m, $T, $v) = shift;

	return ( pow( sqrt($m / (2 * $self->{PI} * $self->{k} * $T)), 3) *
			exp ( - $m*$v*$v / (2 * $self->{k} * $T)));	

}

1;
