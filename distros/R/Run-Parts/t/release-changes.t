#!perl -T

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}


use strict;
use warnings;
use 5.010;

use Test::More;

my $min_tcc = 0.23;
eval "use Test::CPAN::Changes $min_tcc";
plan skip_all => "Test::CPAN::Changes >= $min_tcc required for this test" if $@;
changes_ok();
