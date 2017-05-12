#!/usr/local/bin/perl -w

use Quantum::Superpositions;

use Benchmark;

my $count = shift || 1000;

print "\nTiming prime generated for primes from 1..$count.";
print "\nTimings are displayed for groups of 10 primes.";
print "\nVERSION = $Quantum::Superpositions::VERSION";


my $numprime = 0;

my $last = Benchmark->new;

# primes are either the number 2 or any value with
# all the values in the range range of (2..sqrt(number)+1)
# all having a module with the number.
#
# for example, 29 is prime because 29 % all(2..6) != 0 is 
# true. 
#
# or:  29 % 2, 29 % 3 ... 29 % 6 all have a remainder.

sub is_prime
{
	$_[0]==2 || $_[0] % all(2..sqrt($_[0])+1) != 0
}

# print the time to generate every 10th prime.
# cumulative times help average out fluctuations
# due to clustering of primes.

for( 1..$count )
{
	next unless is_prime( $_ );

	next if ++$numprime % 10;

	# recycling $this avoids benchmarking the print
	# and Benchmark calls.

	my $this = Benchmark->new;

	print "\n$_\t$numprime\t", timestr( timediff($this, $last) );

	$last = $this;
}

print "\n\n";

0

__END__
