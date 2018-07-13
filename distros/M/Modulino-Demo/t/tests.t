use Test::More;

my @classes = qw(
	Modulino::Demo
	Modulino::Demo2
	Modulino::Base
	Modulino::Test
	Modulino::TestWithBase
	);

foreach my $class ( @classes ) {
	use_ok( $class ) or BAILOUT( "$class did not compile" );
	}

done_testing();
