use strict;
use warnings;

use Test::More 1;
my $class = 'Set::CrossProduct';

subtest 'sanity' => sub {
	use_ok $class or BAIL_OUT( "$class did not compile" );
	can_ok $class, 'nth';
	};

subtest 'warnings' => sub {
	my @apples  = ('Granny Smith', 'Washington', 'Red Delicious');
	my @oranges = ('Navel', 'Florida');

	no warnings;

	my $cross = $class->new( [ \@apples ] );
	ok ! defined $cross, 'Single array returns undef';
	};

done_testing();
