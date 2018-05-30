use Test::More 1;

my @classes = qw(PPI::App::ppi_version::BDFOY);

foreach my $class ( @classes ) {
	print "Bail out! $class did not compile\n" unless use_ok( $class );
	}

done_testing();
