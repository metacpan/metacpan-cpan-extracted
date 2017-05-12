use Test::More qw/no_plan/;
use Test::Exception;
use Test::Chado::DBManager::Pg;
use Test::DatabaseRow;
use Test::Chado::FixtureLoader::Flatfile;
use File::ShareDir qw/module_dir/;
use File::Spec::Functions;

SKIP: {
    skip 'Environment variable TC_DSN is not set',
        if not defined $ENV{TC_DSN};
    eval { require DBD::Pg };
    skip 'DBD::Pg is needed to run this test' if $@;

    subtest 'loading organism fixture from flatfile' => sub {
        my $dbmanager = Test::Chado::DBManager::Pg->new(
            dsn      => $ENV{TC_DSN},
            user     => $ENV{TC_USER},
            password => $ENV{TC_PASS}
        );

        $dbmanager->deploy_schema;

        my $loader = Test::Chado::FixtureLoader::Flatfile->new(
            dbmanager => $dbmanager );
        local $Test::DatabaseRow::dbh = $dbmanager->dbh;

        lives_ok { $loader->load_organism } 'should load organism fixture';
        row_ok(
            sql         => "SELECT * FROM organism",
            results     => 12,
            description => 'should have 12 organisms'
        );
        row_ok(
            sql   => "SELECT * FROM organism where common_name = 'human'",
            tests => [ 'genus' => 'Homo', 'species' => 'sapiens' ],
            description => 'should have human entry'
        );
        row_ok(
            sql => "SELECT * FROM organism where abbreviation = 'A.gambiae'",
            tests => [
                'genus'       => 'Anopheles',
                'species'     => 'gambiae',
                'common_name' => 'mosquito'
            ],
            description => 'should have mosquito'
        );

        $dbmanager->drop_schema;
    };

    subtest 'loading relation ontology fixture from flatfile' => sub {

        my $dbmanager = Test::Chado::DBManager::Pg->new(
            dsn      => $ENV{TC_DSN},
            user     => $ENV{TC_USER},
            password => $ENV{TC_PASS}
        );
        $dbmanager->deploy_schema;
        my $loader = Test::Chado::FixtureLoader::Flatfile->new(
            dbmanager => $dbmanager );
        local $Test::DatabaseRow::dbh = $dbmanager->dbh;

        my $sql = <<'SQL';
    SELECT CVTERM.* from CVTERM join CV on CV.CV_ID=CVTERM.CV_ID 
    WHERE CV.NAME = 'relationship';
SQL

        lives_ok { $loader->load_rel }
        'should load relation ontology fixture';
        row_ok(
            results     => 26,
            description => 'should have 26 relation ontology terms',
            sql         => $sql
        );

        $sql = <<'SQL';
    SELECT CVTERM.* from CVTERM JOIN CV on CV.CV_ID=CVTERM.CV_ID
    WHERE CV.NAME = 'relationship' AND CVTERM.NAME = 'located_in'
SQL
        row_ok(
            sql         => $sql,
            results     => 1,
            description => 'should have term located_in'
        );

        $sql = <<'SQL';
    SELECT CVTERM.* from CVTERM JOIN CV on CV.CV_ID=CVTERM.CV_ID
    WHERE CV.NAME = 'relationship' AND CVTERM.NAME IN('adjacent_to','contained_in')
SQL
        row_ok(
            sql         => $sql,
            results     => 2,
            description => 'should have term adjacent_to and contained_in'
        );
        $dbmanager->drop_schema;
    };

    subtest 'loading sequence ontology fixture from flatfile' => sub {

        my $dbmanager = Test::Chado::DBManager::Pg->new(
            dsn      => $ENV{TC_DSN},
            user     => $ENV{TC_USER},
            password => $ENV{TC_PASS}
        );
        $dbmanager->deploy_schema;
        my $loader = Test::Chado::FixtureLoader::Flatfile->new(
            dbmanager => $dbmanager );
        local $Test::DatabaseRow::dbh = $dbmanager->dbh;

        lives_ok { $loader->load_so } 'should load sequence ontology fixture';

        my $sql = <<'SQL';
    SELECT CVTERM.* from CVTERM join CV on CV.CV_ID=CVTERM.CV_ID 
    WHERE CV.NAME = 'sequence';
SQL

        row_ok(
            results     => 287,
            description => 'should have 287 sequence ontology terms',
            sql         => $sql
        );

        $sql = <<'SQL';
    SELECT CVTERM.* from CVTERM JOIN CV on CV.CV_ID=CVTERM.CV_ID
    WHERE CV.NAME = 'sequence' AND CVTERM.NAME = 'contig'
SQL
        row_ok(
            sql         => $sql,
            results     => 1,
            description => 'should have term contig'
        );

        $sql = <<'SQL';
    SELECT CVTERM.* from CVTERM JOIN CV on CV.CV_ID=CVTERM.CV_ID
    WHERE CV.NAME = 'sequence' AND CVTERM.NAME IN('chromosome','gene', 'polypeptide')
SQL
        row_ok(
            sql         => $sql,
            results     => 3,
            description => 'should have these three SO terms'
        );
        $dbmanager->drop_schema;
    };

    subtest 'loading all fixtures from flatfile' => sub {

        my $dbmanager = Test::Chado::DBManager::Pg->new(
            dsn      => $ENV{TC_DSN},
            user     => $ENV{TC_USER},
            password => $ENV{TC_PASS}
        );
        $dbmanager->deploy_schema;
        my $loader = Test::Chado::FixtureLoader::Flatfile->new(
            dbmanager => $dbmanager );
        local $Test::DatabaseRow::dbh = $dbmanager->dbh;

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

        $dbmanager->drop_schema;
    };

    subtest 'loading arbitary ontology fixture from flatfile' => sub {

        my $dbmanager = Test::Chado::DBManager::Pg->new(
            dsn      => $ENV{TC_DSN},
            user     => $ENV{TC_USER},
            password => $ENV{TC_PASS}
        );

        $dbmanager->deploy_schema;
        my $loader = Test::Chado::FixtureLoader::Flatfile->new(
            dbmanager => $dbmanager );
        local $Test::DatabaseRow::dbh = $dbmanager->dbh;

        lives_ok {
            $loader->obo_xml(
                catfile( module_dir('Test::Chado'), 'evidence_code.obo_xml' )
            );
        }
        'should set the obo xml file for loading';

        lives_ok { $loader->load_ontology } 'should load the ontology';

        $sql = <<'SQL';
    SELECT CVTERM.* from CVTERM JOIN CV on CV.CV_ID=CVTERM.CV_ID
    WHERE CV.NAME LIKE 'evidence%' AND CVTERM.NAME = 'curator inference'
SQL
        row_ok(
            sql         => $sql,
            results     => 1,
            description => 'should have term curator inference'
        );
        $dbmanager->drop_schema;
    };
}
