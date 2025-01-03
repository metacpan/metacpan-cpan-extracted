use strict;
use warnings;

use Test::More 1;

my $class  = 'Set::CrossProduct';
my $method = 'labeled';

subtest 'sanity' => sub {
	use_ok $class or BAIL_OUT( "$class did not compile" );
	can_ok $class, $method;
	};

subtest 'unlabeled' => sub {
	my $cross = $class->new( [ [1,2,3], [qw(q c b)] ] );
	isa_ok $cross, $class;
	can_ok $cross, $method;
	ok ! $cross->$method(), 'This cross product is not labelled';
	isa_ok $cross->get, ref [], 'unlabeled get returns array reference';
	};

subtest 'labeled' => sub {
	my $cross = $class->new( {
		numbers => [1,2,3],
		letters => [ qw(q c b) ]
		} );
	isa_ok $cross, $class;
	can_ok $cross, $method;
	ok $cross->$method(), 'This cross product is labelled';
	isa_ok $cross->get, ref {}, 'labeled get returns hash reference';
	};

done_testing();
