#!perl -w
use strict;
use warnings;
use Test::Pod::Coverage;
use Test::More;

# Pod::Find doesn't use require() but traverses @INC manually. *sigh*
BEGIN { unshift @INC, @Devel::SearchINC::inc if @Devel::SearchINC::inc }
plan skip_all => "pod coverage tests turned off in environment"
  if $ENV{PERL_SKIP_POD_COVERAGE_TESTS};
all_pod_coverage_ok();
