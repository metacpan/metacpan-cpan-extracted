package Stats::Fermi::DeltaPotential;

sub new {
	my ($class) = @_;
	my $self = {
	};

	$class = ref($class) || $class;

	bless $self, $class;
}

sub difference {

	my ($self, $a, $x, $m, $T, $v, $DiracFunc, $Boltzmann) = @_;

	return ($Boltzmann->funcall($m, $T, $v) - $DiracFunc->funcall($a,$x)); 

}

1;
