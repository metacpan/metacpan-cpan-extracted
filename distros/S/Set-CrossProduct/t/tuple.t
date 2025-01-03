use strict;
use warnings;

use Test::More 1;
my $class = 'Set::CrossProduct';

subtest 'sanity' => sub {
	use_ok $class or BAIL_OUT( "$class did not compile" );
	can_ok $class, qw(new);
	};

my @apples  = ('Granny Smith', 'Washington', 'Red Delicious');
my @oranges = ('Navel', 'Florida');
my $cross;

subtest 'setup' => sub {
	$cross = $class->new( [ \@apples, \@oranges ] );
	isa_ok $cross, $class;
	can_ok $class, qw(get next previous unget);
	is $cross->cardinality, 6, 'Cardinality is 6' ;
	};

my @table = (
	[ get      => [ $apples[0], $oranges[0] ] ],
	[ next     => [ $apples[0], $oranges[1] ] ],
	[ get      => [ $apples[0], $oranges[1] ] ],
	[ previous => [ $apples[0], $oranges[1] ] ],
	[ get      => [ $apples[1], $oranges[0] ] ],
	[ unget    => $cross ],
	[ get      => [ $apples[1], $oranges[0] ] ],
	[ get      => [ $apples[1], $oranges[1] ] ],
	[ get      => [ $apples[2], $oranges[0] ] ],
	[ get      => [ $apples[2], $oranges[1] ] ],
	);

foreach my $row ( @table ) {
	my( $method, $expected ) = @$row;
	is_deeply scalar $cross->$method(), $expected, $method;
	};

ok $cross->done, 'iterator is exhausted';
is $cross->get, undef, 'at end gets undef';
is $cross->next, undef, 'at end next undef';

done_testing();
