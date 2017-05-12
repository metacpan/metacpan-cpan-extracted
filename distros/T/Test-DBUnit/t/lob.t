use strict;
use warnings;

use Test::More tests => 9;

my $class;

BEGIN {
    $class = 'DBUnit';
    use_ok($class, ':all');
}


my $dbunit = $class->new(connection_name => 'test');
isa_ok($dbunit, $class);

{
    my @exp_dataset = (
        t1 => [col1 => 1, col2 => 3],
        t2 => [col12 => 1, col8 => 3],
        t1 => [col5 => 1, col7 => 3],
    );
    my $result = $dbunit->_exp_table_with_column(\@exp_dataset);
    
    is_deeply($result, {
        t1 => [qw(col1 col2 col5 col7)],
        t2=> [qw(col12 col8)],
    }, 'should have expected tables with columns');
}


SKIP: {
    
    skip('missing env varaibles DB_TEST_CONNECTION, DB_TEST_USERNAME DB_TEST_PASSWORD', 6)

      unless $ENV{DB_TEST_CONNECTION};
    use DBIx::Connection;
    my $connection = DBIx::Connection->new(
        name     => 'test',
        dsn      => $ENV{DB_TEST_CONNECTION},
        username => $ENV{DB_TEST_USERNAME},
        password => $ENV{DB_TEST_PASSWORD},
        no_cache => 1,
    );

    {
        my $script = "t/sql/". $connection->dbms_name . "/create_schema.sql";
        $dbunit->reset_schema($script);
    }
    
    {
        my $script = "t/sql/". $connection->dbms_name . "/populate_schema.sql";
        $dbunit->populate_schema($script);
    }

    {
        print "## insert load strategy tests\n";
        #insert load strategy
	#adds some random data
        $connection->do("INSERT INTO emp (empno, ename) VALUES(1, 'test')");
	$connection->do("INSERT INTO bonus (ename, sal) VALUES('test', 10.4)");

        is($dbunit->load_strategy, INSERT_LOAD_STRATEGY, 'should have insert load strategy');
	my %emp_1 = (empno => 1, ename => 'scott', deptno => 10, job => 'consultant');
	my %emp_2 = (empno => 2, ename => 'john',  deptno => 10, job => 'consultant');
	my %bonus = (ename => 'scott', job => 'consultant', sal => 30);
        $dbunit->dataset(
            emp   => [%emp_1],
            emp   => [%emp_2],
            bonus => [%bonus],
            lob_test => [id => 1, name => 'name 1',
                blob_content => {
                    file => 't/bin/data1.bin',
                    size_column => 'doc_size'
                }
            ]
        );


        
    	my $diff = $dbunit->expected_dataset(
            emp   => [%emp_1],
            emp   => [%emp_2],
            bonus => [%bonus],
            lob_test => [id => 1, name => 'name 1',
                blob_content => {
                    file => 't/bin/data2.bin',
                    size_column => 'doc_size'
                }
	    ]
        );
	
	like($diff, qr{found difference at LOB value lob_test.blob_content}, 'should find difference at lob');

        my $errors = $dbunit->expected_dataset(
            emp   => [%emp_1],
            emp   => [%emp_2],
            bonus => [%bonus],
            lob_test => [id => 1, name => 'name 1',
                blob_content => {
                    file => 't/bin/data1.bin',
                    size_column => 'doc_size'
                }
            ]
        );

	ok(! $errors, 'should validate dataset');

    }
    
    
    
    
    {
        my $script = "t/sql/". $connection->dbms_name . "/create_schema.sql";
        $dbunit->reset_schema($script);
    }
    
    {
        my $script = "t/sql/". $connection->dbms_name . "/populate_schema.sql";
        $dbunit->populate_schema($script);
    }

    {
        print "## refresh load strategy tests\n";
        #refresh load strategy
        $dbunit->set_load_strategy(REFRESH_LOAD_STRATEGY);
        is($dbunit->load_strategy, REFRESH_LOAD_STRATEGY, 'should have insert load strategy');

	#adds some random data
        $connection->do("INSERT INTO emp (empno, ename) VALUES(1, 'test')");
	$connection->do("INSERT INTO bonus (ename, sal) VALUES('test', 10.4)");

    
    	my %emp_1 = (empno => 1, ename => 'scott', deptno => 10, job => 'consultant');
	my %emp_2 = (empno => 2, ename => 'john',  deptno => 10, job => 'consultant');
	my %bonus = (ename => 'scott', job => 'consultant', sal => 30);
        $dbunit->dataset(
            emp   => [%emp_1],
            emp   => [%emp_2],
            bonus => [%bonus],
            lob_test => [
		id 	     => 1, 
		name	     => 'name 1',
                blob_content => {
                    file => 't/bin/data1.bin',
                    size_column => 'doc_size'
                }
            ]
        );


        
    	my $diff = $dbunit->expected_dataset(
            emp   => [%emp_1],
            emp   => [%emp_2],
            bonus => [%bonus],
            lob_test => [id => 1, name => 'name 1',
                blob_content => {
                    file => 't/bin/data2.bin',
                    size_column => 'doc_size'
                }
            ]
        );
	like($diff, qr{found difference at LOB value lob_test.blob_content}, 'should find difference at lob');

        my $errors = $dbunit->expected_dataset(
            emp   => [%emp_1],
            emp   => [%emp_2],
            bonus => [%bonus],
            lob_test => [id => 1, name => 'name 1',
                blob_content => {
                    file 	=> 't/bin/data1.bin',
                    size_column => 'doc_size'
                }
            ]
        );

	ok(! $errors, 'should validate dataset');

    }
    
}
