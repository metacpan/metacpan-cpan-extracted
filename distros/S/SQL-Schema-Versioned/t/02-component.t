#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use Data::Clone;
use DBI;
use File::chdir;
use File::Path qw(remove_tree);
use File::Temp qw(tempdir);
use SQL::Schema::Versioned qw(create_or_update_db_schema);

my $dir = tempdir(CLEANUP => 0);
$CWD = $dir;
note "Tempdir = $dir";
my $dbh;

sub connect_db {
    my ($dsn, $user, $pass);
    if ($dsn = $ENV{TEST_DBI_DSN}) {
        $user = $ENV{TEST_DBI_USER};
        $pass = $ENV{TEST_DBI_PASS};
    } else {
        $dsn = "dbi:SQLite:$dir/db.db";
        $user = "";
        $pass = "";
    }
    $dbh = DBI->connect($dsn, $user, $pass, {RaiseError=>1});
}

sub reset_db {
    $dbh->begin_work;
    $dbh->do("DROP TABLE IF EXISTS $_") for qw(t1 t2 t3 t4 t5 t6 meta);
    $dbh->commit;
}

connect_db();

subtest "missing install/provides" => sub {
    reset_db();

    my $spec = {
        component_name => 'c1',
        latest_v => 2,
        install_v1 => [],
        upgrade_to_v2 => [],
    };
    my $res = create_or_update_db_schema(dbh => $dbh, spec => $spec);
    is($res->[0], 412);
};

subtest "missing dep" => sub {
    reset_db();

    my $spec1 = {
        component_name => 'c1',
        latest_v => 1,
        install => [
            'CREATE TABLE t1 (i INT)',
        ],
    };
    my $res1 = create_or_update_db_schema(dbh => $dbh, spec => $spec1);
    is($res1->[0], 200) or diag explain $res1;

    my $spec2 = {
        component_name => 'c2',
        latest_v => 1,
        deps => {
            t3 => 0,
        },
        install => [
            'CREATE TABLE t2 (i INT)',
        ],
    };

    my $res2 = create_or_update_db_schema(dbh => $dbh, spec => $spec2);
    is($res2->[0], 412) or diag explain $res2;
};

subtest "unsatisfied version" => sub {
    reset_db();

    my $spec1 = {
        component_name => 'c1',
        latest_v => 1,
        install => [
            'CREATE TABLE t1 (i INT)',
        ],
    };
    my $res1 = create_or_update_db_schema(dbh => $dbh, spec => $spec1);
    is($res1->[0], 200) or diag explain $res1;

    my $spec2 = {
        component_name => 'c2',
        latest_v => 1,
        deps => {
            t1 => 2,
        },
        install => [
            'CREATE TABLE t2 (i INT)',
        ],
    };

    my $res2 = create_or_update_db_schema(dbh => $dbh, spec => $spec2);
    is($res2->[0], 412) or diag explain $res2;
};

subtest "conflict" => sub {
    reset_db();

    my $spec1 = {
        component_name => 'c1',
        latest_v => 1,
        install => [
            'CREATE TABLE t1 (i INT)',
        ],
    };
    my $res1 = create_or_update_db_schema(dbh => $dbh, spec => $spec1);
    is($res1->[0], 200) or diag explain $res1;

    my $spec2 = {
        component_name => 'c2',
        latest_v => 1,
        install => [
            'CREATE TABLE t1 (i INT)',
        ],
    };

    my $res2 = create_or_update_db_schema(dbh => $dbh, spec => $spec2);
    is($res2->[0], 412) or diag explain $res2;
};

subtest "upgrade: provides the same table" => sub {
    reset_db();

    my $spec_v1 = {
        component_name => 'c1',
        latest_v => 1,
        install => [
            'CREATE TABLE t1 (i INT)',
        ],
    };
    my $res1 = create_or_update_db_schema(dbh => $dbh, spec => $spec_v1);
    is($res1->[0], 200) or diag explain $res1;

    my $spec_v2 = {
        component_name => 'c1',
        latest_v => 2,
        provides => ['t1'],
        upgrade_to_v2 => [
            'ALTER TABLE t1 ADD COLUMN j INT',
        ],
    };

    my $res2 = create_or_update_db_schema(dbh => $dbh, spec => $spec_v2);
    is($res2->[0], 200) or diag explain $res2;
};

subtest "upgrade: no longer provides a table" => sub {
    reset_db();

    my $spec_v1 = {
        component_name => 'c1',
        latest_v => 1,
        install => [
            'CREATE TABLE t1 (i INT)',
            'CREATE TABLE t2 (i INT)',
        ],
    };
    my $res1 = create_or_update_db_schema(dbh => $dbh, spec => $spec_v1);
    is($res1->[0], 200) or diag explain $res1;

    my %provides;

    %provides = SQL::Schema::Versioned::_get_provides_from_db($dbh);
    is_deeply(
        \%provides,
        {t1=>[c1=>1], t2=>[c1=>1]},
    ) or diag explain \%provides;

    my $spec_v2 = {
        component_name => 'c1',
        latest_v => 2,
        provides => ['t1'],
        upgrade_to_v2 => [
            'DROP TABLE t2',
        ],
    };

    my $res2 = create_or_update_db_schema(dbh => $dbh, spec => $spec_v2);
    is($res2->[0], 200) or diag explain $res2;

    %provides = SQL::Schema::Versioned::_get_provides_from_db($dbh);
    is_deeply(
        \%provides,
        {t1=>[c1=>2]},
    ) or diag explain \%provides;
};

subtest "basics" => sub {
    reset_db();

    my $spec1 = {
        component_name => 'c1',
        latest_v => 1,
        install => [
            'CREATE TABLE t1 (i INT)',
        ],
    };
    my $res1 = create_or_update_db_schema(dbh => $dbh, spec => $spec1);
    is($res1->[0], 200) or diag explain $res1;

    my $spec2 = {
        component_name => 'c2',
        latest_v => 1,
        deps => {
            t1 => 0,
        },
        install => [
            'CREATE TABLE t2 (i INT)',
        ],
    };

    my $res2 = create_or_update_db_schema(dbh => $dbh, spec => $spec2);
    is($res2->[0], 200) or diag explain $res2;

    my %provides;

    %provides = SQL::Schema::Versioned::_get_provides_from_db($dbh);
    is_deeply(
        \%provides,
        {t1=>[c1=>1], t2=>[c2=>1]},
    ) or diag explain \%provides;

};

DONE_TESTING:
done_testing;
if (Test::More->builder->is_passing) {
    $CWD = "/";
    remove_tree($dir);
} else {
    diag "Tests failing, not removing tmpdir $dir";
}
