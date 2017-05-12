#! /usr/bin/perl
#---------------------------------------------------------------------

use Test::More;

eval "use Test::Pod::Coverage 1.08; 1"
or plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage";

eval "use Pod::Coverage::TrustPod 0.100001; 1"
or plan skip_all => "Pod::Coverage::TrustPod 0.100001 required for testing POD coverage";

my $opts = { coverage_class => 'Pod::Coverage::TrustPod' };

plan tests => 4;

pod_coverage_ok('PostScript::File', $opts);
pod_coverage_ok('PostScript::File::Functions', $opts);
pod_coverage_ok('PostScript::File::Metrics', $opts);
pod_coverage_ok('PostScript::File::Metrics::Loader', $opts);
