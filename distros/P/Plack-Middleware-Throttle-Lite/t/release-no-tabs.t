
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.05

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Plack/Middleware/Throttle/Lite.pm',
    'lib/Plack/Middleware/Throttle/Lite/Backend/Abstract.pm',
    'lib/Plack/Middleware/Throttle/Lite/Backend/Simple.pm'
);

notabs_ok($_) foreach @files;
done_testing;
