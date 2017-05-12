use strict;
use Test::More qw/no_plan/;
use Test::Exception;
use Test::DatabaseRow;
use SQL::Abstract;

use_ok('Test::Chado::DBManager::Pg');
my $pg = new_ok 'Test::Chado::DBManager::Pg';

SKIP: {
    skip 'Environment variable TC_DSN is not set',
        if not defined $ENV{TC_DSN};
    eval { require DBD::Pg };
    skip 'DBD::Pg is needed to run this test' if $@;

    $pg->dsn( $ENV{TC_DSN} );
    $pg->user( $ENV{TC_USER} );
    $pg->password( $ENV{TC_PASS} );

    local $Test::DatabaseRow::dbh = $pg->dbh;
    my $sqla = SQL::Abstract->new;

    subtest 'custom pg backend with DBI' => sub {

        my $namespace = $pg->schema_namespace;
        like( $namespace, qr/^\w+$/,
            'should match an alphanumeric namespace' );

        lives_ok { $pg->deploy_by_dbi } 'should deploy with dbi';
        row_ok(
            table       => "information_schema.tables",
            where       => [ "table_schema" => $namespace ],
            results     => 173,
            description => 'should have all existing tables'
        );

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

        my $namespace = $pg->schema_namespace;

        row_ok(
            table       => "information_schema.tables",
            where       => [ "table_schema" => $namespace ],
            results     => 173,
            description => 'should have all existing tables'
        );

        row_ok(
            sql => [
                $sqla->select(
                    'information_schema.tables',
                    "*",
                    {   "table_schema" => $namespace,
                        "table_name" =>
                            { -in => [qw/db feature cv cvterm dbxref/] }
                    }
                )
            ],
            results     => 5,
            description => 'should have all four tables'
        );
        lives_ok { $pg->drop_schema } "should drop the schema";

    };
}
