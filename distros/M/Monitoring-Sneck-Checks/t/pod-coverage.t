#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage" if $@;
eval "use Pod::Coverage::CountParents";
plan skip_all => "Pod::Coverage::CountParents required for testing POD coverage" if $@;

# the constants and what each check provides are documented in base
all_pod_coverage_ok(
	{ coverage_class => 'Pod::Coverage::CountParents', also_private => [qr/\A(?:OK|WARNING|CRITICAL|UNKNOWN)\z/] }
);
