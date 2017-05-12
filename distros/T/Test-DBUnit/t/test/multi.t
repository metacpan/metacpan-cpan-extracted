use strict;
use warnings;

use DBIx::Connection;
use Test::More tests => 10;
use Test::DBUnit connection_names => ['test1', 'test2', 'test3'];

SKIP: {
    skip('missing env varaibles DB_TEST_CONNECTION, DB_TEST_USERNAME DB_TEST_PASSWORD', 10)
        unless $ENV{DB_TEST_CONNECTION};

    my $dbh = DBI->connect($ENV{DB_TEST_CONNECTION}, $ENV{DB_TEST_USERNAME}, $ENV{DB_TEST_PASSWORD});


     my $connection = DBIx::Connection->new(
        name     => 'test1',
        dsn      => $ENV{DB_TEST_CONNECTION},
        username => $ENV{DB_TEST_USERNAME},
        password => $ENV{DB_TEST_PASSWORD},
    );


    add_test_connection($connection);

    add_test_connection('test2', dbh => $dbh);
    add_test_connection('test3',
        dsn      => $ENV{DB_TEST_CONNECTION},
        username => $ENV{DB_TEST_USERNAME},
        password => $ENV{DB_TEST_PASSWORD},
    );



    SKIP: {

        my $dbms_name  = $connection->dbms_name;
            skip('Tests are not prepared for ' . $dbms_name , 10)
                unless -d "t/sql/". $connection->dbms_name;
                
      
      
        set_test_connection('test1');
        reset_schema_ok("t/sql/". $connection->dbms_name . "/create_schema.sql");
        populate_schema_ok("t/sql/". $connection->dbms_name . "/populate_schema.sql");
        
        {
            xml_dataset_ok('test1');
            is($connection, test_connection(), 'should have connection object');
        
            $connection->execute_statement("UPDATE emp SET ename = ? WHERE empno = ?", 'Scott', 1);
            $connection->execute_statement("UPDATE emp SET ename = ? WHERE empno = ?", 'John', 2);
            $connection->execute_statement("UPDATE emp SET ename = ? WHERE empno = ?", 'Mark', 3);
            
            expected_xml_dataset_ok('test1');
        }
        
            set_refresh_load_strategy;
            
        {
            dataset_ok(
                emp   => [empno => "1", ename => "scott", deptno => "10", job => "project manager"],
                emp   => [empno => "2", ename => "john",  deptno => "10", job => "engineer"],
                emp   => [empno => "3", ename => "mark",  deptno => "10", job => "sales assistant"],
                bonus => [ename => "scott", job => "project manager", sal => "20"],
            );

            $connection->execute_statement("UPDATE emp SET ename = ? WHERE empno = ?", 'Scott', 1);
            $connection->execute_statement("UPDATE emp SET ename = ? WHERE empno = ?", 'John', 2);
            $connection->execute_statement("UPDATE emp SET ename = ? WHERE empno = ?", 'Mark', 3);

            expected_dataset_ok(
                emp   => [empno => "1", ename => "Scott", deptno => "10", job => "project manager"],
                emp   => [empno => "2", ename => "John",  deptno => "10", job => "engineer"],
                emp   => [empno => "3", ename => "Mark",  deptno => "10", job => "sales assistant"],
                bonus => [ename => "scott", job => "project manager", sal => "20"],
            )
            
        }
        
        set_test_connection('test3');
        set_insert_load_strategy;
        SKIP: {
            skip('Tests are not prepared for ' . $dbms_name , 3)
                if($dbms_name ne 'PostgreSQL' && $dbms_name ne 'Oracle' && $dbms_name ne 'MySQL');
            
            $connection->execute_statement("DELETE FROM emp");
            test2_reset_sequence_ok($dbms_name ne 'MySQL' ? 'emp_seq' : 'emp');
            dataset_ok(
                emp => [ename => "John", deptno => "10", job => "project manager"],
                emp => [ename => "Scott", deptno => "10", job => "project manager"]
            );
            expected_dataset_ok(
                emp => [empno => 1, ename => "John", deptno => "10", job => "project manager"],
                emp => [empno => 2, ename => "Scott", deptno => "10", job => "project manager"]
            )
        }
        
    }
}