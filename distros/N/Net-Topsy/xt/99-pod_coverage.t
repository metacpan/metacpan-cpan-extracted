#!perl
use warnings;
use strict;
use Test::More;

plan skip_all => 'set TEST_POD to enable this test' unless ($ENV{TEST_POD} || -e 'MANIFEST.SKIP');

eval "use Pod::Coverage 0.19";
plan skip_all => 'Pod::Coverage 0.19 required' if $@;

eval "use Test::Pod::Coverage 1.04";
plan skip_all => 'Test::Pod::Coverage 1.04 required' if $@;

plan tests => 1;

pod_coverage_ok('Net::Topsy', {
    also_private => [qr/^BUILD(:?ARGS)?$/],
});
