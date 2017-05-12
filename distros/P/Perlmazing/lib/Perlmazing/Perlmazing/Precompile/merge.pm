use Perlmazing;

sub main (\%@) {
	my $h = shift;
	while (@_ and my ($k, $v) = (shift @_, shift @_)) {
		$h->{$k} = $v;
	}
	%$h;
}

