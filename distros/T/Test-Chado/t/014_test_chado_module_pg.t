use Test::More qw/no_plan/;
use Test::Exception;
use File::Temp qw/tmpnam/;
use Test::DatabaseRow;
use Module::Load qw/load/;
use File::ShareDir qw/module_file/;
use SQL::Abstract;

SKIP: {
    skip 'Environment variable TC_DSN is not set',
        if not defined $ENV{TC_DSN};
    eval { require DBD::Pg };
    skip 'DBD::Pg is needed to run this test' if $@;

    my $sqla = SQL::Abstract->new;

    load Test::Chado, ':all';
    subtest 'schema management with postgresql loader' => sub {
        my $schema;
        lives_ok { $schema = chado_schema() } 'should run chado_schema';
        isa_ok( $schema, 'Bio::Chado::Schema' );

        local $Test::DatabaseRow::dbh
            = get_dbmanager_instance()->dbh;
        my $namespace
            = get_dbmanager_instance()->schema_namespace;

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

        lives_ok { drop_schema() } 'should run drop_schema';

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
            results     => 0,
            description => 'should not have three existing table'
        );
    };

    subtest 'schema and fixture managements with postgresql loader' => sub {
        my $schema;
        lives_ok { $schema = chado_schema( load_fixture => 1 ) }
        'should accept fixture loading option';
        isa_ok( $schema, 'Bio::Chado::Schema' );

        is( $schema->resultset('Organism::Organism')->count( {} ),
            12, 'should loaded 12 organisms' );

        lives_ok { reload_schema() } 'should reloads the schema';

        local $Test::DatabaseRow::dbh
            = get_dbmanager_instance()->dbh;
        my $namespace
            = get_dbmanager_instance()->schema_namespace;

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
        row_ok(
            sql         => "SELECT * FROM $namespace.organism",
            results     => 0,
            description => "should not have any fixture after reload"
        );
        lives_ok { drop_schema() } 'should run drop_schema';

    };

    subtest 'loading custom fixtures with postgresql loader' => sub {
        my $schema;
        my $preset = module_file( 'Test::Chado', 'cvpreset.tar.bz2' );
        lives_ok { $schema = chado_schema( custom_fixture => $preset ) }
        'should accept custom fixture';
        isa_ok( $schema, 'DBIx::Class::Schema' );

        local $Test::DatabaseRow::dbh
            = get_dbmanager_instance()->dbh;
        is( $schema->resultset('Cv::Cv')->count( { name => 'cv_property' } ),
            1,
            'should have cv_property ontology'
        );
        lives_ok { drop_schema() } 'should run drop_schema';
    };

}
