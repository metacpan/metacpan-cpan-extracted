BEGIN {
	@classes = qw(SourceCode::LineCounter::Perl);
	}

use Test::More;

foreach my $class ( @classes ) {
	print "Bail out! $class did not compile\n" unless use_ok( $class );
	}

done_testing();
