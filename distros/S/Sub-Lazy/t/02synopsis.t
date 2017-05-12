use strict;
use Test::More;
use Sub::Lazy;

my $it_happens = 0;

sub double :Lazy {
	$it_happens++;  # side-effect
	
	my $n = shift;
	return $n * 2;
}

my $eight = double(4);

# The 'double' function hasn't been executed yet.
is($it_happens, 0);

# The correct answer was calculated.
is($eight, 8);

# The 'double' function was executed when necessary.
is($it_happens, 1);

done_testing;
