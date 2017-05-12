use strict;
use warnings;
use Test::More;
eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;

plan tests => 1;
pod_coverage_ok("MooseX::Traits::SetScalarByRef", "MooseX::Traits::SetScalarByRef is covered");