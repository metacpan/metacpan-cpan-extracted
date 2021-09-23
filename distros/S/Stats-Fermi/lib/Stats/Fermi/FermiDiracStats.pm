package Stats::Fermi::FermiDiracStats;

sub new {
	my ($class) = @_;
	my $self = {
		k => 1.380649 * pow(10,-23), 
	};

	$class = ref($class) || $class;

	bless $self, $class;
}

sub funcall {

	my ($self, $e, $mu, $T) = shift;

	return (1 / (exp(($e-$mu)/($self->{k}*$T)) + 1));
}

1;
