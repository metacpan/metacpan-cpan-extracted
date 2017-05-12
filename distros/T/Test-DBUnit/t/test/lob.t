use strict;
use warnings;

use DBIx::Connection;
use Test::More tests => 5;
use Test::DBUnit connection_name => 'test';




SKIP: {
    skip('missing env varaibles DB_TEST_CONNECTION, DB_TEST_USERNAME DB_TEST_PASSWORD', 5)
        unless $ENV{DB_TEST_CONNECTION};
     my $connection = DBIx::Connection->new(
        name     => 'test',
        dsn      => $ENV{DB_TEST_CONNECTION},
        username => $ENV{DB_TEST_USERNAME},
        password => $ENV{DB_TEST_PASSWORD},
    );


    SKIP: {

        my $dbms_name  = $connection->dbms_name;
            skip('Tests are not prepared for ' . $dbms_name , 5)
                unless -d "t/sql/". $connection->dbms_name;
                
      
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
    }
}