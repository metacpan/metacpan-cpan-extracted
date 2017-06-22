#! perl -w

use strict;
use warnings;

use DBI;
use Test::More;
use Test::DB::Shared::mysqld;

# use Log::Any::Adapter qw/Stderr/;
use File::Which;
unless( File::Which::which('mysqld') ){
    plan skip_all => 'Test irrelevant without mysqld';
}



my $db_pid;

Test::DB::Shared::mysqld->load( { args => [ './t/testmysqld.json' ]} );

{
    ok( my $testdb = Test::DB::Shared::mysqld->new(
        test_namespace => 'blabla',
        my_cnf => {
            'skip-networking' => '', # no TCP socket
        }
    ) );
    ok( $testdb->dsn() , "Ok got dsn");
    ok( $db_pid = $testdb->pid() , "Ok got SQL pid");
    ok( kill( 0, $db_pid ), "Ok db pid is running");
    cmp_ok( $testdb->test_namespace() , 'ne' , 'blabla' , "Ok namespace is not what we asked" );
    like( $testdb->test_namespace(), qr/^mynamespace/ , "Ok good plugged-in namespace" );
    ok( ! $testdb->_holds_mysqld() , "Ok not main mysqld holder");
}

Test::DB::Shared::mysqld->tear_down_plugin_instance();

ok( ! kill( 0, $db_pid ), "Ok db pid is NOT running (was teared down by the scope escape)");


done_testing();
