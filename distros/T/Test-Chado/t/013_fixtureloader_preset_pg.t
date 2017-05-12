use Test::More qw/no_plan/;
use Test::Exception;
use Test::Chado::DBManager::Pg;
use File::ShareDir qw/module_file/;
use File::Spec::Functions;
use Test::DatabaseRow;

use_ok('Test::Chado::FixtureLoader::Preset');
SKIP: {
    skip 'Environment variable TC_DSN is not set',
        if not defined $ENV{TC_DSN};
    eval { require DBD::Pg };
    skip 'DBD::Pg is needed to run this test' if $@;

    subtest 'loading all fixtures from preset' => sub {
        my $dbmanager = Test::Chado::DBManager::Pg->new(
            dsn      => $ENV{TC_DSN},
            user     => $ENV{TC_USER},
            password => $ENV{TC_PASS}
        );

        $dbmanager->deploy_schema;
        local $Test::DatabaseRow::dbh = $dbmanager->dbh;

        my $loader = new_ok('Test::Chado::FixtureLoader::Preset');
        lives_ok { $loader->dbmanager($dbmanager) }
        'should set the dbmanager';
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

        $dbmanager->drop_schema;
    };

    subtest 'loading custom fixtures from preset' => sub {


        my $dbmanager = Test::Chado::DBManager::Pg->new(
            dsn      => $ENV{TC_DSN},
            user     => $ENV{TC_USER},
            password => $ENV{TC_PASS}
        );

        $dbmanager->deploy_schema;
        local $Test::DatabaseRow::dbh = $dbmanager->dbh;

        my $loader = new_ok('Test::Chado::FixtureLoader::Preset');
        lives_ok { $loader->dbmanager($dbmanager) }
        'should set the dbmanager';

        my $preset = module_file( 'Test::Chado', 'cvpreset.tar.bz2' );
        lives_ok { $loader->load_custom_fixtures($preset) }
        'should load fixtures from preset';

        row_ok(
            sql         => "SELECT * FROM cv where name = 'cv_property'",
            results     => 1,
            description => 'should have cv_property ontology'
        );
        row_ok(
            sql         => "SELECT * FROM db",
            results     => 2,
            description => 'should have 2 db table rows'
        );

        my $sql = <<'SQL';
    SELECT CVTERM.* from CVTERM join CV on CV.CV_ID=CVTERM.CV_ID 
    WHERE CV.NAME = 'cv_property';
SQL

        row_ok(
            results     => 13,
            description => 'should have 13 cv_property terms',
            sql         => $sql
        );

        $sql = <<'SQL';
    SELECT CVTERM.* from CVTERM join CV on CV.CV_ID=CVTERM.CV_ID 
    WHERE CV.NAME = 'cv_property' and CVTERM.IS_RELATIONSHIPTYPE = 1;
SQL

        row_ok(
            results => 13,
            description =>
                'should have 13 cv_property terms as relationship type',
            sql => $sql
        );

        $sql = <<'SQL';
    SELECT children.* from cvterm parent 
        JOIN cvterm_relationship cvrel 
            ON parent.cvterm_id = cvrel.object_id 
        JOIN cvterm children 
            ON children.cvterm_id = cvrel.subject_id
        WHERE parent.name = 'cv_property';

SQL

        row_ok(
            results     => 11,
            description => 'should have 11 children',
            sql         => $sql
        );

        $sql = <<'SQL';
    SELECT DBXREF.* from CVTERM join CV on CV.CV_ID=CVTERM.CV_ID 
    join dbxref ON dbxref.dbxref_id = cvterm.dbxref_id
    WHERE CV.NAME = 'cv_property';
SQL
        row_ok(
            results     => 13,
            description => 'should have 13 cv_property accession',
            sql         => $sql
        );

        $dbmanager->drop_schema;

    };
}
