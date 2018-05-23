BEGIN {
	@classes = qw(ReturnValue);
	}

use Test::More tests => scalar @classes;

foreach my $class ( @classes )
	{
	print "Bail out! $class did not compile\n" unless use_ok( $class );
	}
