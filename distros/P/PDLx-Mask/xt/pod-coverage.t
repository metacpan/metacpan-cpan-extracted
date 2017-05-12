#!perl 

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

my @modules = grep { ! /Validate/ } all_modules();
pod_coverage_ok( $_ ) for @modules;

done_testing;
