package Stats::Fermi::DiracFunc;

sub new {
	my ($class) = @_;
	my $self = {
		hbar => 1.054571817 * pow(10,-34), ### reduced Planck constant
		c => 299792458,
		G => 6.67430 * pow(10, -11),
		kB => 1.380649 * pow(10, -23),
		PI => 3.14152,
	};

	$class = ref($class) || $class;

	bless $self, $class;
}

sub funcall {

	my (@self, $solarmass) = shift;

	return ($self->{hbar} * pow($self->{c},3) / 
		(8 * $self->{PI} * $self->{G} * $self->{kB} * $solarmass));
}

1;
