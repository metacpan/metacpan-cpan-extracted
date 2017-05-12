use Test::More 0.95;

my $class = 'Set::CrossProduct';
use_ok( $class );

my @apples  = ('Granny Smith', 'Washington', 'Red Delicious');
my @oranges = ('Navel', 'Florida');

my $i = Set::CrossProduct->new( [ \@apples, \@oranges ] );
isa_ok( $i, $class );

my $count = $i->cardinality;
is( $count, 6, 'Get back the right number of elements' );

ok( defined $i->next, 'Next element is defined' );	

# after the last fetch, next() should return undef
for( ; $count > 0; $count-- ) {
	my @a = $i->get;
	}
ok( !(defined $i->next), 'Next element is undefined' );	

# but if i unget the last element, next should return
# the last one.
$i->unget;
ok( defined $i->next, 'Next element is defined after unget' );	

# now we should be done
my @a = $i->get;
ok( !( defined $i->next ), 'Next element is undefined after get' );	

done_testing();
