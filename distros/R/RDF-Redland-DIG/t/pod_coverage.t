use Test::More qw(no_plan);
use Test::Pod::Coverage;

my $trustme = { trustme => [qr/^(new)$/] };
pod_coverage_ok( "RDF::Redland::DIG", $trustme );
pod_coverage_ok( "RDF::Redland::DIG::KB", $trustme );

#all_pod_coverage_ok();
