use Perlmazing;

sub main {
	my @call = caller(1);
	if (not defined $call[5]) {
		die "Useless call to $call[3] in void context at $call[1] line $call[2]\n";
	}
}

1;