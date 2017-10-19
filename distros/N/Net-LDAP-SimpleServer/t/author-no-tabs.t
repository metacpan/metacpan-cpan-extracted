
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/ldapd.pl',
    'lib/Net/LDAP/SimpleServer.pm',
    'lib/Net/LDAP/SimpleServer/LDIFStore.pm',
    'lib/Net/LDAP/SimpleServer/ProtocolHandler.pm',
    't/00-compile.t',
    't/00-load.t',
    't/000-report-versions-tiny.t',
    't/05-handler.t',
    't/06-store.t',
    't/13-param.t',
    't/14-bind.t',
    't/15-search.t',
    't/lib/Helper.pm'
);

notabs_ok($_) foreach @files;
done_testing;
