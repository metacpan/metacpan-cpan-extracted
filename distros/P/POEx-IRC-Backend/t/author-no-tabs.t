
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
    'lib/POEx/IRC/Backend.pm',
    'lib/POEx/IRC/Backend/Connect.pm',
    'lib/POEx/IRC/Backend/Connector.pm',
    'lib/POEx/IRC/Backend/Listener.pm',
    'lib/POEx/IRC/Backend/Role/CheckAvail.pm',
    'lib/POEx/IRC/Backend/Role/HasEndpoint.pm',
    'lib/POEx/IRC/Backend/Role/HasWheel.pm',
    'lib/POEx/IRC/Backend/Role/Socket.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/author-no-tabs.t',
    't/backend.t',
    't/backend/connect.t',
    't/backend/connector.t',
    't/backend/listener.t',
    't/inc/test.crt',
    't/inc/test.key',
    't/release-cpan-changes.t',
    't/release-pod-linkcheck.t',
    't/release-pod-syntax.t',
    't/release-unused-vars.t',
    't/ssl.t'
);

notabs_ok($_) foreach @files;
done_testing;
