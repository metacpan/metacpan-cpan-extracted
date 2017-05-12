use strict;
use warnings FATAL => 'all';

use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;

use Test::More;
use Test::Requires { 'Test::Pod::Coverage' => 1.08 };

# Define the overridden methods.
my $trustme = { trustme => [qr/^(TRACE)$/] };

pod_coverage_ok( 'Padre::Plugin::Cookbook', $trustme );
pod_coverage_ok( 'Padre::Plugin::Cookbook::Recipe01::Main', $trustme );
pod_coverage_ok( 'Padre::Plugin::Cookbook::Recipe02::Main', $trustme );
pod_coverage_ok( 'Padre::Plugin::Cookbook::Recipe03::Main', $trustme );
pod_coverage_ok( 'Padre::Plugin::Cookbook::Recipe03::About', $trustme );
pod_coverage_ok( 'Padre::Plugin::Cookbook::Recipe04::Main', $trustme );
pod_coverage_ok( 'Padre::Plugin::Cookbook::Recipe04::About', $trustme );

done_testing();

__END__

