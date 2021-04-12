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

	return ($Boltzmann->funcall($a, $x) - $DiracFunc->funcall($m,$T,$v)); 

}

1;
