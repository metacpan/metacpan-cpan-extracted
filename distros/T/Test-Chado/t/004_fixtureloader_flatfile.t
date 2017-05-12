use Test::More qw/no_plan/;
use Test::Exception;
use Test::Chado::DBManager::Sqlite;
use File::ShareDir qw/module_dir/;
use File::Spec::Functions;
use Test::DatabaseRow;

use_ok('Test::Chado::FixtureLoader::Flatfile');
subtest 'attributes in flatfile fixtureloader' => sub {
    my $dbmanager = Test::Chado::DBManager::Sqlite->new();

    my $loader = new_ok('Test::Chado::FixtureLoader::Flatfile');
    lives_ok { $loader->dbmanager($dbmanager) } 'should set the dbmanager';
    is( $loader->namespace, 'test-chado', 'should have a default namespace' );
    isa_ok( $loader->fixture_manager,
        'Test::Chado::FixtureManager::Flatfile' );
    isa_ok( $loader->obo_xml_loader, 'XML::Twig' );
    isa_ok( $loader->graph,          'Graph' );
    isa_ok( $loader->traverse_graph, 'Graph::Traversal::BFS' );

    lives_ok {
        $loader->obo_xml(
            catfile( module_dir('Test::Chado'), 'sofa.obo_xml' ) );
    }
    'should set obo_xml attribute';
    is( $loader->ontology_namespace, 'sequence',
        'should have parsed ontology namespace' );
};

subtest 'loading organism fixture from flatfile' => sub {
    my $dbmanager = Test::Chado::DBManager::Sqlite->new();
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
        sql         => "SELECT * FROM organism where common_name = 'human'",
        tests       => [ 'genus' => 'Homo', 'species' => 'sapiens' ],
        description => 'should have human entry'
    );
    row_ok(
        sql   => "SELECT * FROM organism where abbreviation = 'A.gambiae'",
        tests => [
            'genus'       => 'Anopheles',
            'species'     => 'gambiae',
            'common_name' => 'mosquito'
        ],
        description => 'should have mosquito'
    );
};

subtest 'loading relation ontology fixture from flatfile' => sub {
    my $dbmanager = Test::Chado::DBManager::Sqlite->new();
    $dbmanager->deploy_schema;
    my $loader = Test::Chado::FixtureLoader::Flatfile->new(
        dbmanager => $dbmanager );
    local $Test::DatabaseRow::dbh = $dbmanager->dbh;

    my $sql = <<'SQL';
    SELECT CVTERM.* from CVTERM join CV on CV.CV_ID=CVTERM.CV_ID 
    WHERE CV.NAME = 'relationship';
SQL

    lives_ok { $loader->load_rel } 'should load relation ontology fixture';
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
};

subtest 'loading sequence ontology fixture from flatfile' => sub {
    my $dbmanager = Test::Chado::DBManager::Sqlite->new();
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
};

subtest 'loading all fixtures from flatfile' => sub {
    my $dbmanager = Test::Chado::DBManager::Sqlite->new();
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
};

subtest 'loading arbitary ontology fixture from flatfile' => sub {
    my $dbmanager = Test::Chado::DBManager::Sqlite->new();
    $dbmanager->deploy_schema;
    my $loader = Test::Chado::FixtureLoader::Flatfile->new(
        dbmanager => $dbmanager );
    local $Test::DatabaseRow::dbh = $dbmanager->dbh;

    lives_ok {
        $loader->obo_xml(
            catfile( module_dir('Test::Chado'), 'evidence_code.obo_xml' ) );
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
};
