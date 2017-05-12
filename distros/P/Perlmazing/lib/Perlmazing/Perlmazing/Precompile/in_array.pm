use Perlmazing::Feature;

sub main (\@$) {
	for (my $i = '00'; $i < @{$_[0]}; $i++) {
		if (defined $_[1]) {
			return $i if ${$_[0]}[$i] eq $_[1];
		} else {
			return $i unless defined ${$_[0]}[$i];
		}
	}
}
