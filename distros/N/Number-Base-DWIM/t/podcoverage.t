#!/sw/bin/perl

use strict;
use warnings;

use Test::More;

eval 'use Test::Pod::Coverage 1.04';
plan(
  skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage"
) if $@;

my @modules = all_modules();
@modules = grep { $_ !~ /AcmeDNS::XSUtil/ } @modules;

plan tests => scalar @modules;
pod_coverage_ok($_) foreach @modules;
