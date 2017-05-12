use Perlmazing;

sub main ($$) {
	my ($aa, $bb) = ($_[0], $_[1]);
	if (is_number $aa and is_number $bb) {
		my $r = $aa <=> $bb;
		return $r if $r;
		$aa cmp $bb;
	} elsif (is_number $aa) {
		-1;
	} elsif (is_number $bb) {
		1;
	} elsif (defined($aa) and defined($bb)) {
		if ($aa =~ /\d/ and $bb =~ /\d/) {
			my @split_a = split /(\d+)/, $aa;
			my @split_b = split /(\d+)/, $bb;
			my $current_sort = 0;
			my $cmp_sort = '';
			while (1) {
				my $break = 1;
				last unless @split_a and @split_b;
				my ($aa, $bb) = (shift(@split_a), shift(@split_b));
				if (is_number $aa and is_number $bb) {
					$current_sort = $aa <=> $bb;
					unless ($current_sort) {
						$current_sort = $aa cmp $bb;
						$cmp_sort = $current_sort unless $cmp_sort;
						$break = 0;
					}
				} elsif (is_number $aa) {
					$current_sort = -1;
				} elsif (is_number $bb) {
					$current_sort = 1;
				} else {
					$current_sort = $aa cmp $bb;
				}
				return $current_sort if $current_sort and $break;
			}
			return $cmp_sort if $cmp_sort;
			$current_sort;
		} else {
			$aa cmp $bb;
		}
	} elsif (defined $aa) {
		1;
	} elsif (defined $bb) {
		-1;
	} else {
		0;
	}
}

