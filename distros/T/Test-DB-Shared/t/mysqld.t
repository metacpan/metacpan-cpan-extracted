#! perl -w

use strict;
use warnings;

use DBI;
use Test::More;
use Test::DB::Shared::mysqld;

# use Log::Any::Adapter qw/Stderr/;

my $db_pid;
{
    ok( my $testdb = Test::DB::Shared::mysqld->new(
        test_namespace => 'mysqld_t',
        my_cnf => {
            'skip-networking' => '', # no TCP socket
        }
    ) );

    $testdb->_monitor(sub{
                          $testdb->_monitor(sub{
                                                pass("Can nest monitors with no deadlocks");
                                            });
                      });
    ok( $testdb->dsn() , "Ok got dsn");
    ok( $db_pid = $testdb->pid() , "Ok got SQL pid");
    ok( kill( 0, $db_pid ), "Ok db pid is running");

    my $dbh = DBI->connect($testdb->dsn(), 'root', '', { RaiseError => 1 } );
    ok( $dbh->ping(), "Ok can connect to the local test database");
    ok( $dbh->do('CREATE TABLE bla( foo INTEGER PRIMARY KEY NOT NULL )') );
    my $rows = $dbh->selectall_arrayref('SELECT * FROM test.pid_registry');
    is( $rows->[0]->[0] , $$ , "The pid of this test is registered");

    # # Build another one.
    my $other = Test::DB::Shared::mysqld->new(
        test_namespace => 'mysqld_t',
        my_cnf => {
            'skip-networking' => '', # no TCP socket
        }
    );
    ok( $other->dsn() , "Ok get another DSN");
}

ok( ! kill( 0, $db_pid ), "Ok db pid is NOT running (was teared down by the scope escape)");


done_testing();
