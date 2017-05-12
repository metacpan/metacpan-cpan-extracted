use strict;
use warnings;
use Test::More;
use Module::CPANTS::Kwalitee;

local $INC{"Test/Kwalitee.pm"} = 1;
local $Test::Kwalitee::VERSION = 1.01;

my @hardcoded_metrics = qw/
  extractable
  has_readme
  has_manifest
  has_meta_yml
  has_buildtool
  has_changelog
  no_symlinks
  has_tests
  proper_libs
  no_pod_errors
  use_strict
  has_test_pod
  has_test_pod_coverage
/;

my %seen;
my $kwalitee = Module::CPANTS::Kwalitee->new;
for my $generator (@{ $kwalitee->generators }) {
  for (@{ $generator->kwalitee_indicators }) {
    $seen{$_->{name}}++ if ref $_->{code} eq ref sub {};
  }
}

for (@hardcoded_metrics) {
  is $seen{$_} => 1, "$_ is available for Test::Kwalitee";
}

done_testing;
