use strict;
use warnings;
use Test::More 'no_plan';

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

my $parms = { trustme => [qr/^(new|SNA_(ego|nodal|group|actor|path).*)$/] };

#all_pod_coverage_ok( { trustme => [qr/^(new)$/] } );
for my $module (qw(Easy
		   Server
		   Server4
		   Repository
		   Repository4
		   Session4
		   Transaction4
		   Catalog
		   Catalog4)) {
    pod_coverage_ok('RDF::AllegroGraph::'.$module, $parms);
}
pod_coverage_ok('RDF::AllegroGraph', $parms);
