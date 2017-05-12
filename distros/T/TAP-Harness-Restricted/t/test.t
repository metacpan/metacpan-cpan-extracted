use 5.008001;
use strict;
use warnings;
use Test::More 0.96;
use Test::FailWarnings;
use Path::Tiny;
use File::pushd qw/tempd/;

# monkey patch TAP::Harness
BEGIN {
    $INC{'TAP/Harness.pm'} = 1;
    *TAP::Harness::aggregate_tests = sub { return @_ };
    $TAP::Harness::VERSION = 3.18;
}

use TAP::Harness::Restricted;

my $wd = tempd;

$ENV{HARNESS_SKIP} = 't/*skipped.t';

my @filter_on_name = map { "t/$_" } qw(
  pod.t
  99-pod.t
  99_pod.t
  pod-coverage.t
  99-pod-coverage.t
  99_pod_coverage.t
  skipped.t
  99_skipped.t
  99-skipped.t
);

path($_)->touchpath for @filter_on_name;

my %bad_content = (
    't/foo.t' => <<'HERE',
use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();
HERE

    't/bar.t' => <<'HERE',
use Test::More;
eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;
plan tests => 1;
pod_coverage_ok( "Pod::Master::Html");
HERE
);

for my $k ( keys %bad_content ) {
    my $f = path($k);
    $f->touchpath;
    $f->spew( $bad_content{$k} );
}

my @ok_files = qw(
  t/ok.t
  t/also_ok.t
);

path($_)->touchpath for @ok_files;

my ( undef, undef, @got ) =
  TAP::Harness::Restricted->aggregate_tests( undef, @filter_on_name, @ok_files,
    keys %bad_content );

is_deeply( [ sort @got ], [ sort @ok_files ], "files filtered" );

done_testing;
#
# This file is part of TAP-Harness-Restricted
#
# This software is Copyright (c) 2013 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
# vim: ts=4 sts=4 sw=4 et:
