use Perlmazing;
use List::Util;

sub main {
	my @call = caller(0);
	my @copy = List::Util::shuffle(@_);
	if (wantarray) {
		return @copy;
	} elsif (defined wantarray) {
		return $_[0];
	} else {
		for (my $i = 0; $i < @copy; $i++) {
			eval {
				$_[$i] = $copy[$i];
			};
			if (my $e = $@) {
				if ($e =~ /^Modification of a read\-only value attempted/) {
					die "Modification of a read-only value attempted at $call[1] line $call[2]\n";
				} else {
					die "$e\n...from call at $call[1] line $call[2]\n";
				}
			}
		}
	}
}

1;