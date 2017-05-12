use strict;
use warnings FATAL => 'all';

use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;

BEGIN {
	unless ($ENV{RELEASE_TESTING}) {
		use Test::More;
		Test::More::plan(skip_all => 'Release Candidate testing, not required for installation.');
	}
}

use Test::Requires { 'Test::Pod::Coverage' => 1.08 };

# Define the three overridden methods.
my $trustme = { trustme => [qr/^(TRACE)$/] };

pod_coverage_ok( "Padre::Plugin::SpellCheck", $trustme );
pod_coverage_ok( "Padre::Plugin::SpellCheck::Checker", $trustme );
pod_coverage_ok( "Padre::Plugin::SpellCheck::Engine", $trustme );
pod_coverage_ok( "Padre::Plugin::SpellCheck::Preferences", $trustme );

done_testing();

__END__

