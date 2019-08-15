
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

use strict;
use warnings;
use Test::More;
eval "use Test::Kwalitee 1.27 qw(kwalitee_ok)";
plan skip_all => "Test::Kwalitee 1.27 required to test distribution Kwalitee" if $@;
kwalitee_ok();
done_testing;
