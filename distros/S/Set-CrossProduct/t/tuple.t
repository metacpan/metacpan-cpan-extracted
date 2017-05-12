use Test::More 0.95;

my $class = 'Set::CrossProduct';
use_ok( $class );

my @apples  = ('Granny Smith', 'Washington', 'Red Delicious');
my @oranges = ('Navel', 'Florida');

my $i = Set::CrossProduct->new( [ \@apples, \@oranges ] );
isa_ok( $i, $class );

is( $i->cardinality, 6, 'Cardinality is 6' );

my $tuple = $i->get;
ok( $tuple->[0] eq $apples[0] and $tuple->[1] eq $oranges[0] );

$tuple = $i->next;
ok( $tuple->[0] eq $apples[0] and $tuple->[1] eq $oranges[1] );

$tuple = $i->get;
ok( $tuple->[0] eq $apples[0] and $tuple->[1] eq $oranges[1] );

$tuple = $i->previous;
ok( $tuple->[0] eq $apples[0] and $tuple->[1] eq $oranges[1] );

$status = $i->unget;
ok( $status );

$tuple = $i->get;
ok( $tuple->[0] eq $apples[0] and $tuple->[1] eq $oranges[1] );

$tuple = $i->get;
ok( $tuple->[0] eq $apples[1] and $tuple->[1] eq $oranges[0] );

$tuple = $i->get;
ok( $tuple->[0] eq $apples[1] and $tuple->[1] eq $oranges[1] );

$tuple = $i->get;
ok( $tuple->[0] eq $apples[2] and $tuple->[1] eq $oranges[0] );

$tuple = $i->get;
ok( $tuple->[0] eq $apples[2] and $tuple->[1] eq $oranges[1] );

ok( !( defined $i->get ), 'Next element is undefined after get' );	

done_testing();
