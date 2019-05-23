
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
    'lib/Test/DBChanges.pm',
    'lib/Test/DBChanges/ChangeSet.pm',
    'lib/Test/DBChanges/Pg.pm',
    'lib/Test/DBChanges/Pg/DBIC.pm',
    'lib/Test/DBChanges/Role/Base.pm',
    'lib/Test/DBChanges/Role/DBI.pm',
    'lib/Test/DBChanges/Role/DBIC.pm',
    'lib/Test/DBChanges/Role/JSON.pm',
    'lib/Test/DBChanges/Role/Pg.pm',
    'lib/Test/DBChanges/Role/Triggers.pm',
    'lib/Test/DBChanges/TableChangeSet.pm',
    't/bin/build-dbic-schema',
    't/fixtures/data-pg.sql',
    't/fixtures/schema-pg.sql',
    't/lib/Test/DBChanges/Schema.pm',
    't/lib/Test/DBChanges/Schema/Result/T1.pm',
    't/lib/Test/DBChanges/Schema/Result/T2.pm',
    't/lib/Test/DBChanges/Schema/Result/T3.pm',
    't/lib/Test/DBChanges/Test.pm',
    't/tests/pg-dbic.t',
    't/tests/pg.t'
);

notabs_ok($_) foreach @files;
done_testing;
