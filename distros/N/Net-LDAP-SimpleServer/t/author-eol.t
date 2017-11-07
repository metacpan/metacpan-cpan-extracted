
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/simpleldap',
    'lib/Net/LDAP/SimpleServer.pm',
    'lib/Net/LDAP/SimpleServer/Constant.pm',
    'lib/Net/LDAP/SimpleServer/LDIFStore.pm',
    'lib/Net/LDAP/SimpleServer/ProtocolHandler.pm',
    't/00-compile.t',
    't/00-load.t',
    't/000-report-versions-tiny.t',
    't/10-store.t',
    't/20-handler.t',
    't/30-param.t',
    't/40-bind.t',
    't/41-bind-user.t',
    't/50-search.t',
    't/51-search-pw_attr.t',
    't/lib/Helper.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
