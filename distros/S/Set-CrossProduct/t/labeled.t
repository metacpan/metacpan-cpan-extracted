use strict;
use warnings;

use Test::More 1;

my $Class = 'Set::CrossProduct';
use_ok( $Class );

subtest unlabeled => sub {
	my $cross = $Class->new( [ [1,2,3], [qw(q c b)] ] );
	isa_ok( $cross, $Class );
	can_ok( $cross, qw(labeled) );
	ok( ! $cross->labeled, 'This cross product is not labelled' );
	};

subtest unlabeled => sub {
	my $cross = $Class->new( {
		numbers => [1,2,3],
		letters => [ qw(q c b) ]
		} );
	isa_ok( $cross, $Class );
	can_ok( $cross, qw(labeled) );
	ok( $cross->labeled, 'This cross product is labelled' );
	};

done_testing();
