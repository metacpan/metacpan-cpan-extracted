use Perlmazing;

sub main ($) {
	my $x = shift();
	return 0 unless (defined($x) and length($x));
	return 1;
}

