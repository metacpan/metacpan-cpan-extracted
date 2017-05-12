#!perl -w
use Test::More;
use strict;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

my $trustparents = { coverage_class => qw(Pod::Coverage::CountParents) };
#pod_coverage_ok($_, $trustparents) foreach qw(<MODULE NAME>);
all_pod_coverage_ok($trustparents);
