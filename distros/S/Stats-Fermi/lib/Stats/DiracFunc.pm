package Stats::Fermi::DiracFunc;

sub new {
	my ($class) = @_;
	my $self = {
		PI => 3.14152,
	};

	$class = ref($class) || $class;

	bless $self, $class;
}

sub funcall {

	my (@self, $a, $x) = shift;
	### NOTE not abs(a)
	return (1 / ( $a * sqrt($self->{PI}) ) * exp(- ($x/$a) * ($x/$a)));
}

1;
