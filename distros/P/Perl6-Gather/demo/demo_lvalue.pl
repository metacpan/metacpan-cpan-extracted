use Perl6::Gather;

# Doesn't work yet. Perl 5 doesn't support lvalue array return values :-(

my @array = (1..100);

gather {
	my @primes = (2);
	for my $elem (@array) {
		next if grep { $elem % $_ == 0 } @primes;
		take $elem;
		push @primes, $elem;
	}
} = ();

print @array;
