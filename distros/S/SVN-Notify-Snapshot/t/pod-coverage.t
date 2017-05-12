#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

my $trustparents = { coverage_class => 'Pod::Coverage::CountParents' };
plan tests => 1;
pod_coverage_ok( "SVN::Notify::Snapshot", $trustparents );
