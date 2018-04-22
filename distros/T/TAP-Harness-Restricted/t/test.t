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
  99_podcoverage.t
  skipped.t
  99_skipped.t
  99-skipped.t
  release-kwalitee.t
  99_pod_spell.t
  99-perlcritic.t
);

path($_)->touchpath for @filter_on_name;

my @bad_test = qw(
  Test::CleanNamespaces
  Test::DependentModules
  Test::EOL
  Test::Kwalitee
  Test::Mojibake
  Test::NoTabs
  Test::Perl::Critic
  Test::Pod
  Test::Pod::Coverage
  Test::Pod::No404s
  Test::Portability::Files
  Test::Spelling
  Test::Vars
);

my @bad_content;
for my $test (@bad_test) {
    my $file = "t/$test.t";
    $file =~ s/::/_/g;
    $file =~ tr/A-Z/a-z/;
    push @bad_content, $file;

    my $f = path($file);
    $f->touchpath;

    my $content = <<"    HERE";
        use Test::More;
        eval "use $test";
        plan skip_all => "$test required for testing pod coverage" if \$@;
        plan tests => 1;
        is 1, 1;
    HERE
    $content =~ s/^\s+//gm;

    $f->spew($content);
}

my @ok_files = qw(
  t/ok.t
  t/also_ok.t
);

path($_)->touchpath for @ok_files;

my ( undef, undef, @got ) =
  TAP::Harness::Restricted->aggregate_tests( undef, @filter_on_name, @ok_files,
    @bad_content );

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
