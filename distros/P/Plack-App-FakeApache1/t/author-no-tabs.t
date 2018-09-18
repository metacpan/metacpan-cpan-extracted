
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
    'lib/Plack/App/FakeApache1.pm',
    'lib/Plack/App/FakeApache1/Constants.pm',
    'lib/Plack/App/FakeApache1/Handler.pm',
    'lib/Plack/App/FakeApache1/Request.pm',
    'lib/Plack/App/FakeModPerl1.pm',
    'lib/Plack/App/FakeModPerl1/Dispatcher.pm',
    'lib/Plack/App/FakeModPerl1/Server.pm',
    't/00-load.t',
    't/10.fakeapache1.t',
    't/10.plack.app.fakemodperl1.t',
    't/50-app/00.fakeapache1.t',
    't/50-app/testapp.conf',
    't/50-app/testapp.psgi',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/release-kwalitee.t'
);

notabs_ok($_) foreach @files;
done_testing;
