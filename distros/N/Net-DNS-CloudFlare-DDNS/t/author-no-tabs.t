
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Net/DNS/CloudFlare/DDNS.pm',
    'lib/Net/DNS/CloudFlare/DDNS/Types.pm',
    't/00-compile.t',
    't/01-main.t'
);

notabs_ok($_) foreach @files;
done_testing;
