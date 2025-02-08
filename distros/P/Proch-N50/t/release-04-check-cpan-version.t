
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

use strict;
use warnings;
use Test::More;
eval 'use Test::GreaterVersion';
plan skip_all => 'Test::GreaterVersion required for this test' if $@;
has_greater_version_than_cpan('Proch::N50');
done_testing();
