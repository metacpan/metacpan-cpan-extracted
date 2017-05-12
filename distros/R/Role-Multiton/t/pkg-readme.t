#!perl

use Test::More;
plan skip_all => 'pkg/README tests are only run in RELEASE_TESTING mode.' unless $ENV{'RELEASE_TESTING'};

eval 'use Test::CPAN::README 0.2';
plan skip_all => 'Test::CPAN::README v0.2 required for testing the pkg/README file' if $@;

readme_ok();    # this does the plan
