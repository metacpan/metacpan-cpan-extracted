use Perlmazing;

sub main () {
	my @call = caller(1);
	(not $call[5] and defined $call[5]) ? 1 : 0;
}

