use Perlmazing;

sub main () {
	my @call = caller(1);
	(not defined $call[5]) ? 1 : 0;
}

