use Test::More 1;

my @classes = qw(PPI::App::ppi_version::BRIANDFOY);

foreach my $class ( @classes ) {
	BAIL_OUT "$class did not compile" unless use_ok( $class );
	}

done_testing();
