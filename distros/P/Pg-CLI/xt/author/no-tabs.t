use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Pg/CLI.pm',
    'lib/Pg/CLI/Role/Connects.pm',
    'lib/Pg/CLI/Role/Executable.pm',
    'lib/Pg/CLI/Role/HasVersion.pm',
    'lib/Pg/CLI/createdb.pm',
    'lib/Pg/CLI/dropdb.pm',
    'lib/Pg/CLI/pg_config.pm',
    'lib/Pg/CLI/pg_dump.pm',
    'lib/Pg/CLI/pg_restore.pm',
    'lib/Pg/CLI/psql.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/createdb.t',
    't/dropdb.t',
    't/lib/Test/PgCLI.pm',
    't/pg_config.t',
    't/pg_dump.t',
    't/pg_restore.t',
    't/psql.t'
);

notabs_ok($_) foreach @files;
done_testing;
