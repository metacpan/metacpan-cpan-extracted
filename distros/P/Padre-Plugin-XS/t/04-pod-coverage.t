use strict;
use warnings FATAL => 'all';

use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;

BEGIN {
	unless ($ENV{RELEASE_TESTING}) {
		use Test::More;
		Test::More::plan(skip_all => 'Author tests, not required for installation.');
	}
}

use Test::Requires { 'Test::Pod::Coverage' => 1.08 };

# Define the three overridden methods.
my $trustme = { trustme => [qr/^(TRACE)$/] };

pod_coverage_ok('Padre::Plugin::XS', $trustme );
pod_coverage_ok('Padre::Plugin::XS::Document', $trustme );
pod_coverage_ok('Padre::Plugin::XS::PerlXS', $trustme );

done_testing();

__END__

