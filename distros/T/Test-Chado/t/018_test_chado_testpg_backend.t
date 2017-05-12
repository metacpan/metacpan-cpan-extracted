use Test::More qw/no_plan/;
use Test::Exception;
use Test::DatabaseRow;
use Module::Load;

SKIP: {
    skip 'Environment variable TC_TESTPG not set',
        if not exists $ENV{TC_TESTPG};
    eval { require Test::PostgreSQL };
    skip 'Test::PostgreSQL is needed to run this test' if $@;

    subtest 'schema and fixture managements with testpg' => sub {
        local @ARGV = ('--testpg');

        load Test::Chado, ':all';

        my $schema;
        lives_ok { $schema = chado_schema() } 'should run chado_schema';
        isa_ok( $schema, 'Bio::Chado::Schema' );
        isa_ok( get_dbmanager_instance(),
            'Test::Chado::DBManager::Testpg' );

        local $Test::DatabaseRow::dbh
            = get_dbmanager_instance()->dbh;

        my $sql = <<'SQL';
               SELECT reltype FROM pg_class where 
                 relnamespace = (SELECT oid FROM 
                 pg_namespace where nspname = 'public')
                 and relname IN('feature', 'dbxref', 'cvterm')
SQL
        row_ok(
            sql         => $sql,
            results     => 3,
            description => 'should have three existing table'
        );

        lives_ok { drop_schema() } 'should run drop_schema';
        row_ok(
            sql         => $sql,
            results     => 0,
            description => 'should not have three existing table'
        );

        lives_ok { $schema = chado_schema( load_fixture => 1 ) }
        'should accept fixture loading option';
        isa_ok( $schema, 'Bio::Chado::Schema' );

        is( $schema->resultset('Organism::Organism')->count( {} ),
            12, 'should loaded 12 organisms' );

        lives_ok { reload_schema() } 'should reloads the schema';

        local $Test::DatabaseRow::dbh
            = get_dbmanager_instance()->dbh;

         $sql = <<'SQL';
               SELECT reltype FROM pg_class where 
                 relnamespace = (SELECT oid FROM 
                 pg_namespace where nspname = 'public')
                 and relname IN('feature')
SQL
        row_ok(
            sql         => $sql,
            results     => 1,
            description => 'should have feature table after loading'
        );
        is( $schema->resultset('Organism::Organism')->count( {} ),
            0, 'should not have any fixture after reload' );

    };
}
