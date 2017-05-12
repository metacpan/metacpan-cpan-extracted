use strict;
use Test::More qw/no_plan/;
use Test::Exception;
use Test::DatabaseRow;
use Module::Load;
use SQL::Abstract;

use_ok('Test::Chado::DBManager::Postgression');
my $pg   = new_ok 'Test::Chado::DBManager::Postgression';
my $sqla = SQL::Abstract->new;

SKIP: {
    skip 'Environment variable TC_POSTGRESSION not set',
        if not exists $ENV{TC_POSTGRESSION};
    eval { require DBD::Pg };
    skip 'DBD::Pg is needed to run this test' if $@;

    lives_ok { $pg->dbh } 'should setup a dbh handle';
    local $Test::DatabaseRow::dbh = $pg->dbh;
    my $namespace = $pg->schema_namespace;

    subtest 'postgression backend with DBI' => sub {
        lives_ok { $pg->deploy_by_dbi } 'should deploy with dbi';
        row_ok(
            sql => [
                $sqla->select(
                    'information_schema.tables',
                    "*",
                    {   "table_schema" => $namespace,
                        "table_name" => { -in => [qw/db feature cv cvterm/] }
                    }
                )
            ],
            results     => 4,
            description => 'should have all four tables'
        );

        lives_ok { $pg->drop_schema } "should drop the schema";
    };

    subtest 'deploy and reset schema with Pg backend' => sub {
        lives_ok { $pg->deploy_schema } 'should deploy';
        lives_ok { $pg->reset_schema } 'should reset the schema';
        row_ok(
            sql => [
                $sqla->select(
                    'information_schema.tables',
                    "*",
                    {   "table_schema" => $namespace,
                        "table_name" => { -in => [qw/db feature cv cvterm/] }
                    }
                )
            ],
            results     => 4,
            description => 'should have all four tables'
        );
        lives_ok { $pg->drop_schema } "should drop the schema";

    };

    subtest 'loading all fixtures from flatfile' => sub {

        $pg->drop_schema;
        $pg->deploy_schema;

        load 'Test::Chado::FixtureLoader::Flatfile';
        my $loader
            = Test::Chado::FixtureLoader::Flatfile->new( dbmanager => $pg );

        lives_ok { $loader->load_fixtures } 'should load all fixtures';

        row_ok(
            sql         => "SELECT * FROM organism",
            results     => 12,
            description => 'should have 12 organisms'
        );

        my $sql = <<'SQL';
    SELECT CVTERM.* from CVTERM join CV on CV.CV_ID=CVTERM.CV_ID
    WHERE CV.NAME = 'sequence';
SQL

        row_ok(
            results     => 286,
            description => 'should have 286 sequence ontology terms',
            sql         => $sql
        );

        $sql = <<'SQL';
    SELECT CVTERM.* from CVTERM join CV on CV.CV_ID=CVTERM.CV_ID
    WHERE CV.NAME = 'relationship';
SQL
        row_ok(
            results     => 26,
            description => 'should have 26 relation ontology terms',
            sql         => $sql
        );
        $pg->drop_schema;
    };

    subtest 'loading all fixtures from preset' => sub {
        $pg->drop_schema;
        $pg->deploy_schema;

        load 'Test::Chado::FixtureLoader::Preset';
        my $loader
            = Test::Chado::FixtureLoader::Preset->new( dbmanager => $pg );

        lives_ok { $loader->load_fixtures }
        'should load fixtures from preset';

        row_ok(
            sql         => "SELECT * FROM organism",
            results     => 12,
            description => 'should have 12 organisms'
        );

        my $sql = <<'SQL';
    SELECT CVTERM.* from CVTERM join CV on CV.CV_ID=CVTERM.CV_ID
    WHERE CV.NAME = 'sequence';
SQL

        row_ok(
            results     => 286,
            description => 'should have 286 sequence ontology terms',
            sql         => $sql
        );

        $sql = <<'SQL';
    SELECT CVTERM.* from CVTERM join CV on CV.CV_ID=CVTERM.CV_ID
    WHERE CV.NAME = 'relationship';
SQL
        row_ok(
            results     => 26,
            description => 'should have 26 relation ontology terms',
            sql         => $sql
        );
        $pg->drop_schema;

    };
}
