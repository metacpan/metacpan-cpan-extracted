#!perl -T
use strict;
use Test::More;

plan skip_all => "Currently not working for Net::Pcap";
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage"
    unless eval "use Test::Pod::Coverage 1.08; 1";

all_pod_coverage_ok({ also_private => [ '^constant$', '^.*_xs$' ] });
