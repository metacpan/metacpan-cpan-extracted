use Perlmazing;

sub main (\@) {
	my $arr = shift;
	$arr = [$arr, @_] unless isa_array $arr;
	my @copy = @$arr;
	my @duplicates;
	my $seen;
	my $undef = undef;
	$undef = bless \$undef, 'undef';
	for (my $i = 0; $i < @copy; $i++) {
		$copy[$i] = $undef if not defined $copy[$i];
		if ($seen->{$copy[$i]}) {
			push @duplicates, splice @copy, $i, 1;
			$i--;
		} else {
			$seen->{$copy[$i]} = 1;
		}
	}
	for my $i (@copy) {
		$i = undef if ref($i) and ref($i) eq 'undef' and $i eq $undef;
	}
	if (list_context()) {
		return @copy;
	} elsif (scalar_context()) {
		return scalar @duplicates;
	} else {
		@$arr = @copy;
	}
}

