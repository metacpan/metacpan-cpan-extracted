BEGIN {
	@classes = qw(
		MyCPAN::App::DPAN
		MyCPAN::App::DPAN::Reporter::AsYAML
		MyCPAN::App::DPAN::Reporter::Minimal
		MyCPAN::App::DPAN::Indexer
		MyCPAN::App::DPAN::CPANUtils
		);
	}

use Test::More tests => scalar @classes;

foreach my $class ( @classes )
	{
	print "Bail out! $class did not compile\n" unless use_ok( $class );
	}
