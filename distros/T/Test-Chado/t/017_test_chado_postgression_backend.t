use strict;
use Test::More qw/no_plan/;
use Test::Exception;
use Test::DatabaseRow;
use Module::Load;
use SQL::Abstract;

SKIP: {
    skip 'Environment variable TC_POSTGRESSION not set',
        if not exists $ENV{TC_POSTGRESSION};
    eval { require DBD::Pg };
    skip 'DBD::Pg is needed to run this test' if $@;

    subtest 'schema and fixture managements with postgression' => sub {

        load Test::Chado, ':all';

        my $sqla = SQL::Abstract->new;

        my $schema;
        lives_ok { $schema = chado_schema() } 'should run chado_schema';
        isa_ok( $schema, 'Bio::Chado::Schema' );
        isa_ok(
            get_dbmanager_instance(),
            'Test::Chado::DBManager::Postgression'
        );

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
            description => 'should not have all four tables'
        );

        lives_ok { $schema = chado_schema( load_fixture => 1 ) }
        'should accept fixture loading option';
        isa_ok( $schema, 'Bio::Chado::Schema' );

        row_ok(
            sql => "SELECT * FROM organism",
            results => 12,
            description => "should have 12 organisms"
        );

        lives_ok { reload_schema() } 'should reloads the schema';

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
            description => 'should have all four tables after reloading'
        );

        row_ok(
            sql => "SELECT * FROM organism",
            results => 0,
            description => "should not have any organisms after reloading"
        );

    };
}
