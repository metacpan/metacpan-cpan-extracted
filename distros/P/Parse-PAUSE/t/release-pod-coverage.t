#!/usr/bin/perl -w

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}


use strict;
use warnings;
use Test::More;

eval "use Test::Pod::Coverage 1.08; use Pod::Coverage::TrustPod; 1"
  or plan skip_all => "POD coverage testing requires Test::Pod::Coverage 1.08 and Pod::Coverage::TrustPod";
 
all_pod_coverage_ok({
    coverage_class => 'Pod::Coverage::TrustPod',
    also_private => [qr/^[A-Z_]+$/]},
);