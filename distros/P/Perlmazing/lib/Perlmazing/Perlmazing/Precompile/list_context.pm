use Perlmazing;

sub main () {
	my @call = caller(1);
	$call[5] ? 1 : 0;
}

