
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
    't/release-kwalitee.t',
    't/release-pod-coverage.t',
    't/release-pod-syntax.t'
);

notabs_ok($_) foreach @files;
done_testing;
