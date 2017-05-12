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
# Define the overridden methods.
my $trustme = { trustme => [qr/^(TRACE)$/] };

pod_coverage_ok( 'Padre::Plugin::YAML', $trustme );
pod_coverage_ok( 'Padre::Plugin::YAML::Document', $trustme );
pod_coverage_ok( 'Padre::Plugin::YAML::Syntax', $trustme );

done_testing();

__END__

