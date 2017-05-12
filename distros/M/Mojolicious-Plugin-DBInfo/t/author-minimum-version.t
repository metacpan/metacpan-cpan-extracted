#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for author testing');
  }
}

use Test::More;

eval "use Test::MinimumVersion";
if ( $@ ) {
  plan skip_all => 'Test::MinimumVersion required for testing POD';
}
else {
  all_minimum_version_from_metajson_ok();
}


