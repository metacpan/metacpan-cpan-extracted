use Test::More 0.95;

my @classes = qw(Set::CrossProduct);

foreach my $class ( @classes ) {
	use_ok( $class ) or BIALOUT();
	}
	
done_testing();
