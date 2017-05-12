
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.17

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Net/DHCP/Constants.pm',
    'lib/Net/DHCP/Packet.pm',
    't/00.load.t',
    't/03.manifest.t',
    't/21-net-dhcp-packet-packinet.t',
    't/22-net-dhcp-packet-options.t',
    't/30-net-dhcp-constants-coverage.t',
    't/51-net-dhcp-packet-new-basic.t',
    't/52-net-dhcp-packet-new-empty.t',
    't/53-net-dhcp-packet-new-broken.t',
    't/author-critic.t',
    't/author-eol.t',
    't/release-distmeta.t',
    't/release-kwalitee.t',
    't/release-pod-coverage.t',
    't/release-pod-syntax.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
