use Test::More qw/no_plan/;
use Test::Exception;
use File::Temp qw/tmpnam/;
use Test::DatabaseRow;
use Module::Load qw/load/;
use File::ShareDir qw/module_file/;
use Class::Unload;
use Module::Load qw/load/;


load Test::Chado, ':all'; 
Test::Chado->ignore_tc_env(1);

subtest 'schema management with default loader' => sub {
    dies_ok {get_dbmanager_instance()} 'should not return a dbmanager instance';
    dies_ok {get_fixture_loader_instance()} 'should not return a fixture loader instance';

    my ($loader,$dbmanager);
    lives_ok { $loader = Test::Chado->_prepare_fixture_loader_instance }
    'should get default fixture loader';
    lives_ok {$dbmanager = get_dbmanager_instance()} 'should get default dbmanager';
    isa_ok($dbmanager,'Test::Chado::DBManager::Sqlite' );
    isa_ok(get_fixture_loader_instance(),'Test::Chado::FixtureLoader::Preset' );
    isa_ok( $loader, 'Test::Chado::FixtureLoader::Preset' );

    my $schema;
    lives_ok { $schema = chado_schema() } 'should run chado_schema';
    isa_ok( $schema, 'DBIx::Class::Schema' );

    $dbmanager = get_dbmanager_instance();
    my @row = $dbmanager->dbh->selectrow_array(
        "SELECT name FROM sqlite_master where
	type = ? and tbl_name = ?", {}, qw/table feature/
    );
    ok( @row, "should have feature table after getting the schema instance" );

    lives_ok { drop_schema() } 'should run drop_schema';
    my @row2 = $dbmanager->dbh->selectrow_array(
        "SELECT name FROM sqlite_master where
	type = ? and tbl_name = ?", {}, qw/table feature/
    );
    isnt( @row2, 1,
        "should not have feature table after dropping the schema" );
    lives_ok { drop_schema() } 'should run drop_schema';
};

subtest 'schema and fixture managements with default loader' => sub {
    my $schema;
    lives_ok { $schema = chado_schema( load_fixture => 1 ) }
    'should accept fixture loading option';
    isa_ok( $schema, 'DBIx::Class::Schema' );

    is( $schema->resultset('Organism')->count( {} ),
        12, 'should loaded 12 organisms' );

    lives_ok { reload_schema() } 'should reloads the schema';
    my @row
        = Test::Chado->_dbmanager_instance->dbh
        ->selectrow_array(
        "SELECT name FROM sqlite_master where
	type = ? and tbl_name = ?", {}, qw/table feature/
        );
    ok( @row, 'should have feature table after reloading' );
    is( $schema->resultset('Organism')->count( {} ),
        0, 'should not have any fixture after reload' );
    lives_ok { drop_schema() } 'should run drop_schema';

};

subtest 'loading custom schema with default loader' => sub {
    my $schema;
    my $preset = module_file( 'Test::Chado', 'cvpreset.tar.bz2' );
    lives_ok { $schema = chado_schema( custom_fixture => $preset ) }
    'should accept custom fixture';
    isa_ok( $schema, 'DBIx::Class::Schema' );

    local $Test::DatabaseRow::dbh
        = Test::Chado->_dbmanager_instance->dbh;

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

    lives_ok { drop_schema() } 'should run drop_schema';

};

