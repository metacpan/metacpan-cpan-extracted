use Perlmazing;

sub main (\@) {
	my $arr = shift;
	my @copy = @$arr;
	my @duplicates;
	my $seen;
	for (my $i = 0; $i < @copy; $i++) {
		if ($seen->{$copy[$i]}) {
			push @duplicates, splice @copy, $i, 1;
			$i--;
		} else {
			$seen->{$copy[$i]} = 1;
		}
	}
	if (list_context()) {
		return @copy;
	} elsif (scalar_context()) {
		return scalar @duplicates;
	} else {
		@$arr = @copy;
	}
}

