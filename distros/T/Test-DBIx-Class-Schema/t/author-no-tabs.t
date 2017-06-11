
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
    'lib/Test/DBIx/Class/Schema.pm',
    't/10.test.dbix.class.schema.t',
    't/11.testdata.t',
    't/20.run_tests.artist.moose_rs.t',
    't/20.run_tests.artist.t',
    't/20.run_tests.cd.t',
    't/20.run_tests.compound_fk.t',
    't/20.run_tests.person.t',
    't/20.run_tests.proxy.t',
    't/20.run_tests.track.t',
    't/30.failing_tests.artist.t',
    't/30.failing_tests.cd.t',
    't/30.failing_tests.track.t',
    't/30.missing_methods.t',
    't/30.todo.skip.t',
    't/40.untested.columns.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/lib/DBHelper.pm',
    't/lib/TDCSTest.pm',
    't/lib/TDCSTest/ResultSet/ArtistMoose.pm',
    't/lib/TDCSTest/Schema.pm',
    't/lib/TDCSTest/Schema/Artist.pm',
    't/lib/TDCSTest/Schema/Audiophile.pm',
    't/lib/TDCSTest/Schema/CD.pm',
    't/lib/TDCSTest/Schema/CDShop.pm',
    't/lib/TDCSTest/Schema/CDShopAudiophile.pm',
    't/lib/TDCSTest/Schema/LinerNotes.pm',
    't/lib/TDCSTest/Schema/Person.pm',
    't/lib/TDCSTest/Schema/Shop.pm',
    't/lib/TDCSTest/Schema/Track.pm',
    't/lib/UnexpectedTest.pm',
    't/lib/UnexpectedTest/Schema.pm',
    't/lib/UnexpectedTest/Schema/Result/SpanishInquisition.pm',
    't/lib/sqlite.sql',
    't/lib/unexpected.sqlite.sql',
    't/release-has-version.t'
);

notabs_ok($_) foreach @files;
done_testing;
