use strict;
use warnings;

use Test::More 1;
my $class = 'Set::CrossProduct';

subtest 'sanity' => sub {
	use_ok $class or BAIL_OUT( "$class did not compile" );
	can_ok $class, 'nth';
	};

subtest 'empty set' => sub {
	my $cross = $class->new( [ [1,2,3], [] ] );
	isa_ok $cross, $class;

	is $cross->cardinality, 0, "Cardinality is zero";
	is $cross->done, 1, "Done is already true (good)";
	isa_ok $cross->combinations, ref [], "Combinations is array ref";
	is scalar @{$cross->combinations}, 0, "Combinations has zero elements";
	};

done_testing();
