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

subtest 'new' => sub {
	$cross = $class->new( { Apples =>  \@apples, Oranges => \@oranges } );
	isa_ok( $cross, $class );
	is( $cross->cardinality, 6, 'Cardinality is 6' );
	ok $cross->{labeled}, 'object knows there are labels';
	};

my @table = (
	[ get      => { Apples => $apples[0], Oranges => $oranges[0] } ],
	[ next     => { Apples => $apples[0], Oranges => $oranges[1] } ],
	[ get      => { Apples => $apples[0], Oranges => $oranges[1] } ],
	[ previous => { Apples => $apples[0], Oranges => $oranges[1] } ],
	[ get      => { Apples => $apples[1], Oranges => $oranges[0] } ],
	[ unget    => $cross ],
	[ get      => { Apples => $apples[1], Oranges => $oranges[0] } ],
	[ get      => { Apples => $apples[1], Oranges => $oranges[1] } ],
	[ get      => { Apples => $apples[2], Oranges => $oranges[0] } ],
	[ get      => { Apples => $apples[2], Oranges => $oranges[1] } ],
	);

foreach my $row ( @table ) {
	my( $method, $expected ) = @$row;

	subtest $method => sub {
		my $tuple = scalar $cross->$method();
		isa_ok $tuple, ref {}, '$tuple';
		is_deeply $tuple, $expected, $method;
		};
	};

ok $cross->done, 'iterator is exhausted';
is $cross->get, undef, 'at end gets undef';
is $cross->next, undef, 'at end next undef';

done_testing();

__END__
my
my $tuple = $cross->get;
ok( $tuple->{Apples} eq $apples[0] and $tuple->{Oranges} eq $oranges[0] );

$tuple = $cross->next;
ok( $tuple->{Apples} eq $apples[0] and $tuple->{Oranges} eq $oranges[1] );

$tuple = $cross->get;
ok( $tuple->{Apples} eq $apples[0] and $tuple->{Oranges} eq $oranges[1] );

$tuple = $cross->previous;
ok( $tuple->{Apples} eq $apples[0] and $tuple->{Oranges} eq $oranges[1] );

is_deeply($tuple, {Apples => $apples[0], Oranges => $oranges[1]}, 'Explicit exact tuple check');

$status = $cross->unget;
ok( $status );

$tuple = $cross->get;
ok( $tuple->{Apples} eq $apples[0] and $tuple->{Oranges} eq $oranges[1] );

$tuple = $cross->get;
ok( $tuple->{Apples} eq $apples[1] and $tuple->{Oranges} eq $oranges[0] );

$tuple = $cross->get;
ok( $tuple->{Apples} eq $apples[1] and $tuple->{Oranges} eq $oranges[1] );

$tuple = $cross->get;
ok( $tuple->{Apples} eq $apples[2] and $tuple->{Oranges} eq $oranges[0] );

$tuple = $cross->get;
ok( $tuple->{Apples} eq $apples[2] and $tuple->{Oranges} eq $oranges[1] );

ok( !( defined $cross->get ), 'Next element is undefined after get' );

done_testing();
