
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

use Test::DependentModules qw( test_all_dependents );
use Test::More;

plan skip_all => 'Make $ENV{TDM_HACK_TESTS} true to run this test'
    unless $ENV{TDM_HACK_TESTS};

test_all_dependents('Devel::StackTrace');
