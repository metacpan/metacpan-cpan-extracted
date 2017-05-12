package Calculator;

sub new
{
	bless {}, shift;
}


sub hello
{
	my $class = shift;
	print STDERR "Hello From Calculator::hello.\n";
	print STDERR "  ";
	foreach (@_) {
		print STDERR "[ $_ ]";
	}
	print STDERR "\n";
	bless {}, $class;
}

sub add
{
shift;
my $sum = 0;

	if ( ref ($_[0]) ) {		# assume this HAS to be an ARRAY
		foreach (@{$_[0]}) {
			$sum += $_;
		}
	}
	else {
		foreach (@_) {
			$sum += $_;
		}
	}

	$sum;
}

1;
__END__
