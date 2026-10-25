#!perl -T

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}


use Test::More;

plan skip_all => "Test::Pod::Coverage - AUTHOR_TESTING not set"
  unless $ENV{AUTHOR_TESTING};

eval "use Test::Pod::Coverage 1.04";
plan skip_all =>
  "Test::Pod::Coverage 1.04 required for testing POD coverage"
  if $@;

all_pod_coverage_ok();
