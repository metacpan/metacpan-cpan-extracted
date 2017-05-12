#!perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}


use Test::More;

eval "use Test::Rinci 0.01";
plan skip_all => "Test::Rinci 0.01 required for testing Rinci metadata"
  if $@;

metadata_in_all_modules_ok();
