use Test::More 0.95;

my $class = 'Set::CrossProduct';
use_ok( $class );

my @apples  = ('Granny Smith', 'Washington', 'Red Delicious');
my @oranges = ('Navel', 'Florida');

my $i = Set::CrossProduct->new( { Apples =>  \@apples, Oranges => \@oranges } );
isa_ok( $i, $class );

is( $i->cardinality, 6, 'Cardinality is 6' );

my $tuple = $i->get;
ok( $tuple->{Apples} eq $apples[0] and $tuple->{Oranges} eq $oranges[0] );

$tuple = $i->next;
ok( $tuple->{Apples} eq $apples[0] and $tuple->{Oranges} eq $oranges[1] );

$tuple = $i->get;
ok( $tuple->{Apples} eq $apples[0] and $tuple->{Oranges} eq $oranges[1] );

$tuple = $i->previous;
ok( $tuple->{Apples} eq $apples[0] and $tuple->{Oranges} eq $oranges[1] );

is_deeply($tuple, {Apples => $apples[0], Oranges => $oranges[1]}, 'Explicit exact tuple check');

$status = $i->unget;
ok( $status );

$tuple = $i->get;
ok( $tuple->{Apples} eq $apples[0] and $tuple->{Oranges} eq $oranges[1] );

$tuple = $i->get;
ok( $tuple->{Apples} eq $apples[1] and $tuple->{Oranges} eq $oranges[0] );

$tuple = $i->get;
ok( $tuple->{Apples} eq $apples[1] and $tuple->{Oranges} eq $oranges[1] );

$tuple = $i->get;
ok( $tuple->{Apples} eq $apples[2] and $tuple->{Oranges} eq $oranges[0] );

$tuple = $i->get;
ok( $tuple->{Apples} eq $apples[2] and $tuple->{Oranges} eq $oranges[1] );

ok( !( defined $i->get ), 'Next element is undefined after get' );

done_testing();
