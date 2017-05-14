
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.13

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Net/UPS.pm',
    'lib/Net/UPS/Address.pm',
    'lib/Net/UPS/ErrorHandler.pm',
    'lib/Net/UPS/Package.pm',
    'lib/Net/UPS/Rate.pm',
    'lib/Net/UPS/Service.pm',
    'lib/Net/UPS/Tutorial.pm',
    't/02address.t',
    't/custom-url.t',
    't/custom-user-agent.t',
    't/data/address',
    't/data/address-bad',
    't/data/address-non-ascii',
    't/data/address-street-level',
    't/data/address-street-level-bad',
    't/data/rate-1-package',
    't/data/rate-2-packages',
    't/data/shop-1-package',
    't/data/shop-2-packages',
    't/lib/Test/Net/UPS.pm',
    't/lib/Test/Net/UPS/Factory.pm',
    't/lib/Test/Net/UPS/NoNetwork.pm',
    't/lib/Test/Net/UPS/Tracing.pm',
    't/missing-sizes.t',
    't/net-ups-live.t',
    't/net-ups-offline.t',
    't/oversized.t'
);

notabs_ok($_) foreach @files;
done_testing;
