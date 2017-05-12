my @classes = qw(
	Pod::WordML
	Pod::WordML::AddisonWesley
	);

use Test::More;

foreach my $class ( @classes ) {
	print "Bail out! $class did not compile\n" unless use_ok( $class );
	}

done_testing();
