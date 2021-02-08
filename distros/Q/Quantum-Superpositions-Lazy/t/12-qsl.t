use v5.24;
use warnings;
use Test::More;
use Mock::Sub;

##############################################################################
# This test checks if QSL is same as Quantum::Superpositions::Lazy
##############################################################################

BEGIN {
	use_ok('Q::S::L', ':all');
}

isa_ok(Q::S::L::, "Quantum::Superpositions::Lazy");

my $pos = superpos(1, 2, 3, 6, 8);

ok !every_state {
	$pos > 1
};

ok one_state {
	$pos < 2
};

ok every_state {
	$pos > 0
};

done_testing;
