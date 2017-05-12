use strict;
use warnings;

use Test::More tests => 99;

my $class;

BEGIN {
    $class = 'DBUnit';
    use_ok($class, ':all');
}


my $dbunit = $class->new(connection_name => 'test');
isa_ok($dbunit, $class);

my $dataset = [
    table1 => [],
    table5 => [],
    table1 => [col1 => 1, col2 => 2],
    table2 => [col1 => 1, col2 => 2],
    table3 => [col1 => 1, col2 => 2],
    table4 => [col1 => 1, col2 => 2],
    table5 => [col1 => 1, col2 => 2],
];



{
    my $sql = "CREATE TABLE table1 (   id integer,   col1 varchar(128) );
CREATE TABLE table2
(
  id integer,
  col1 varchar(128)
);

CREATE OR REPLACE FUNCTION emp_project_details() RETURNS trigger AS '
BEGIN
do dome stuff;
END' plsql;

CREATE SEQUENCE seq1;
";

    my %objects= $dbunit->objects_to_create($sql);
    is_deeply(\%objects,  {
        'TABLE table1' => 'CREATE TABLE table1 (   id integer,   col1 varchar(128) )',
        'TABLE table2' => 'CREATE TABLE table2
(
  id integer,
  col1 varchar(128)
)',

    'FUNCTION emp_project_details' => "CREATE OR REPLACE FUNCTION emp_project_details() RETURNS trigger AS '
BEGIN
do dome stuff;
END' plsql;",
    
    'SEQUENCE seq1' => 'CREATE SEQUENCE seq1'
}, 'should have list of table to create');
}

{
    my @tables = $dbunit->empty_tables_to_delete($dataset);
    is_deeply(\@tables, ['table1', 'table5'], 'should have empty_tables_to_delete');
}

{
    my @tables = $dbunit->tables_to_delete($dataset);
    is_deeply(\@tables, ['table1', 'table5', 'table4' ,'table3', 'table2'], 'should have tables_to_delete');

}

{
    my $sql = "
INSERT INTO dept(deptno, dname, loc)
VALUES(10, 'HR', 'Warsaw');

INSERT INTO dept(deptno, dname, loc)
VALUES(20, 'IT', 'Katowice;'); ";
    my @rows = $dbunit->rows_to_insert($sql);
    is_deeply(\@rows, ['
INSERT INTO dept(deptno, dname, loc)
VALUES(10, \'HR\', \'Warsaw\')',
          '

INSERT INTO dept(deptno, dname, loc)
VALUES(20, \'IT\', \'Katowice;\')',
    ], 'should have rows to insert');
    
}

{
    my $result = DBUnit::compare_datasets({key1 => 1, key2 => 3}, {key1 => 1}, 'table1', 'key1', 'key2');
    is($result, "found difference in table1 key2:
  [ key1 => '1' key2 => '' ]
  [ key1 => '1' key2 => '3' ]", 'should find difference');
}

{
    my $result = DBUnit::compare_datasets({key1 => 1, key2 => 3}, {key1 => 1, key2 => 3.0}, 'table1','key1', 'key2');
    ok(! $result, 'should not find differences');
}


    {
        my $result = $dbunit->load_xml('t/dbunit.dataset.xml');
        
        is_deeply($result->{properties}, {load_strategy => 'INSERT_LOAD_STRATEGY', reset_sequences => undef}, 'should have properties');
        is_deeply($result->{dataset}, [
            emp => [deptno => '10', empno => 1, ename => 'scott', job => 'project manager'],
            emp => [deptno => '10', empno => 2, ename => 'john',  job => 'engineer'],
            emp => [deptno => '10', empno => 3 ,ename => 'mark',  job => 'sales assistant'],
            bonus => [ename => 'scott', job => 'project manager', sal => '20']
        ], 'should have dataset');
    }

SKIP: {
    
    skip('missing env varaibles DB_TEST_CONNECTION, DB_TEST_USERNAME DB_TEST_PASSWORD', 89)

      unless $ENV{DB_TEST_CONNECTION};
    use DBIx::Connection;
    my $connection = DBIx::Connection->new(
        name     => 'test',
        dsn      => $ENV{DB_TEST_CONNECTION},
        username => $ENV{DB_TEST_USERNAME},
        password => $ENV{DB_TEST_PASSWORD},
    );

    {
        my $script = "t/sql/". $connection->dbms_name . "/create_schema.sql";
        $dbunit->reset_schema($script);
        ok(@{$connection->table_info('dept')}, "should have dept table");
        ok(@{$connection->table_info('emp')}, "should have emp table");
    }
    
    {
        my $script = "t/sql/". $connection->dbms_name . "/populate_schema.sql";
        $dbunit->populate_schema($script);
        my $result = $connection->record("SELECT * FROM dept WHERE deptno = ?", 10);
        is_deeply($result, {deptno => 10, dname =>'HR', loc => 'Warsaw'}, 'should have populated data');
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
        );

	{
	    my $record = $connection->record("SELECT empno, ename, deptno, job FROM emp WHERE empno = ?", 1);
            is_deeply($record, \%emp_1, 'should have emp1 row');
	}

	{
	    my $record = $connection->record("SELECT empno, ename, deptno, job FROM emp WHERE empno = ?", 2);
            is_deeply($record, \%emp_2, 'should have emp2 row');
	}

	{
	    my $record = $connection->record("SELECT ename, job, sal FROM bonus WHERE ename = ?", 'scott');
            is_deeply($record, \%bonus, 'should have bonus row');
	}

	{
	    my $record = $connection->record("SELECT COUNT(*) AS cnt FROM bonus");
            is($record->{cnt}, 1, 'should have one bonus row');
	}

	{
	    my $record = $connection->record("SELECT COUNT(*) AS cnt FROM emp");
            is($record->{cnt}, 2, 'should have two emp rows');
	}

        #expected resultset
        $connection->do("INSERT INTO emp (empno, ename) VALUES(20, 'test')");
        $connection->do("INSERT INTO bonus (ename, sal) VALUES('scott', 10.4)");
        $connection->execute_statement("UPDATE emp SET ename = ? WHERE empno = ?", 'John', 2);

        my %emp_20 = (empno => 20, ename => 'test');
        ok(! $dbunit->expected_dataset(
            emp   => [%emp_1],
            emp   => [%emp_2, ename => 'John'],
            emp   => [%emp_20],
            bonus => [%bonus],
            bonus => [ename => 'scott', sal => 10.4],
        ), 'should have expected data');


        ok(! $dbunit->expected_dataset(
            emp   => [%emp_1],
            emp   => [%emp_2, ename => sub {
			  my $val = shift;
			  !! ($val eq 'John');
			}
	        ],
            emp   => [%emp_20],
            bonus => [%bonus],
            bonus => [ename => 'scott', sal => 10.4],
        ), 'should have expected data - code ref');


        ok($dbunit->expected_dataset(
            emp   => [%emp_1],
            emp   => [%emp_2, ename => sub {
			  my $val = shift;
			  !! ($val eq 'John1');
			}
	        ],
            emp   => [%emp_20],
            bonus => [%bonus],
            bonus => [ename => 'scott', sal => 10.4],
        ), 'should not have expected data - code ref');

        
        $connection->do("INSERT INTO bonus (ename, sal) VALUES('scott', 10.4)");
        my $result = $dbunit->expected_dataset(
            emp   => [%emp_1],
            emp   => [%emp_2, ename => 'John'],
            emp   => [%emp_20],
            bonus => [%bonus],
            bonus => [ename => 'scott', sal => '10.4'],
        );
        is($result, "found difference in number of the bonus rows - has 3 rows, should have 2", 'should find difference in number of rows');

        {
            my $result = $dbunit->expected_dataset(emp => [ename => 'Test', empno => 30]);
            like($result, qr{missing row}, 'shuld find difference - missing row');
        }
    
        {
            my $result = $dbunit->expected_dataset(emp => [ename => 'Test', empno => 1  ]);
            like($result, qr{found difference}, 'should find difference');
        }

    }

    {
        print "## refresh load strategy tests\n";
        #refresh load strategy
        $dbunit->set_load_strategy(REFRESH_LOAD_STRATEGY);
        is($dbunit->load_strategy, REFRESH_LOAD_STRATEGY, 'should have insert load strategy');
        
        $connection->do("INSERT INTO emp (empno, ename, deptno, job) VALUES(3, 'john3', 10, 'engineer')");
	my %emp_1 = (empno => 1, ename => 'scott', deptno => 10, job => 'project manager');
	my %emp_2 = (empno => 2, ename => 'john',  deptno => 10, job => 'engineer');
        my %emp_3 = (empno => 3, ename => 'john3',  deptno => 10, job => 'engineer');
	my %bonus = (ename => 'scott', job => 'project manager', sal => 20);
        $dbunit->dataset(
            emp   => [%emp_1],
            emp   => [%emp_2],
            bonus => [%bonus],
        );

	{
	    my $record = $connection->record("SELECT empno, ename, deptno, job FROM emp WHERE empno = ?", 1);
            is_deeply($record, \%emp_1, 'should have emp1 row');
	}
        
	{
	    my $record = $connection->record("SELECT empno, ename, deptno, job FROM emp WHERE empno = ?", 2);
            is_deeply($record, \%emp_2, 'should have emp2 row');
	}

	{
	    my $record = $connection->record("SELECT empno, ename, deptno, job FROM emp WHERE empno = ?", 3);
            is_deeply($record, \%emp_3, 'should have emp3 row');
	}
    
	{
	    my $record = $connection->record("SELECT ename, job, sal FROM bonus WHERE ename = ? AND sal = ?", 'scott', 20);
            is_deeply($record, \%bonus, 'should have bonus row');
	}
    
    
        $connection->execute_statement("UPDATE emp SET ename = ? WHERE empno = ?", 'John', 2);
    
        ok(! $dbunit->expected_dataset(
            emp   => [%emp_1],
            emp   => [%emp_2, ename => 'John'],
            bonus => [%bonus],
        ), 'have expected data');


	ok(! $dbunit->expected_dataset(
            emp   => [%emp_1],
            emp   => [%emp_2, ename => sub {
		my $val = shift;
		!! ($val eq 'John');
		}],
            bonus => [%bonus],
        ), 'have expected data code ref');


	ok($dbunit->expected_dataset(
            emp   => [%emp_1],
            emp   => [%emp_2, ename => sub {
		my $val = shift;
		!! ($val eq 'John1');
		}],
            bonus => [%bonus],
        ), 'have not have expected data code ref');

        
        {
            my $result = $dbunit->expected_dataset(
                emp   => [%emp_1],
                emp   => [%emp_2],
                bonus => [%bonus],
            );
            like($result, qr{found difference}, 'should find difference');
        }

        {
            my $result = $dbunit->expected_dataset(
                emp   => [%emp_1],
                emp   => [%emp_2, ename => 'John'],
                bonus => [%bonus, => sal => 32],
            );
            like($result, qr{missing row}, 'should find difference - missing entry');
        }
    }


    print "## xml dataset tests\n";
    #xml dataset tests  
    {
        $dbunit->xml_dataset('t/dbunit.dataset.xml');
        
	{
	    my $record = $connection->record("SELECT empno, ename, deptno, job FROM emp WHERE empno = ?", 1);
            is_deeply($record, {deptno => '10', empno => 1, ename => 'scott', job => 'project manager'}, 'should have emp1 row');
	}
        
        {
	    my $record = $connection->record("SELECT empno, ename, deptno, job FROM emp WHERE empno = ?", 2);
            is_deeply($record, {deptno => '10', empno => 2, ename => 'john',  job => 'engineer'}, 'should have emp2 row');
	}

        {
	    my $record = $connection->record("SELECT empno, ename, deptno, job FROM emp WHERE empno = ?", 3);
            is_deeply($record, {deptno => '10', empno => 3 ,ename => 'mark',  job => 'sales assistant'}, 'should have emp3 row');
	}

        $connection->execute_statement("UPDATE emp SET ename = ? WHERE empno = ?", 'Scott', 1);
        $connection->execute_statement("UPDATE emp SET ename = ? WHERE empno = ?", 'John', 2);
        $connection->execute_statement("UPDATE emp SET ename = ? WHERE empno = ?", 'Mark', 3);

        ok(! $dbunit->expected_xml_dataset('t/dbunit.resultset.xml'), 'should have all expected data');
    }
    
    ok(!$dbunit->dataset(emp => []), 'should sunc database to dataset');
    my $record = $connection->record("SELECT count(*) as rows_number FROM emp");
    is($record->{rows_number}, 0, "should delete all rows from emp");
    
    if($connection->dbms_name eq 'Oracle') {
        {
            my $result = $dbunit->execute('SELECT SYSDATE INTO :var FROM dual');
            ok($result->{var}, 'should have date');
        }
        {
            my $result = $dbunit->execute('
                SELECT 10 INTO :var1 FROM dual;
                :var2 := 360

            ');
            is($result->{var1}, 10, 'should have var1 bind variable value');
            is($result->{var2}, 360, 'should have var2 bind variable value');
        }
        {
            my ($error_code, $error_message) = $dbunit->throws(':var := 100/0');
            is($error_code, 1476, 'should have error code');
            ok($error_message, 'should have error message');
        }
        {
            my ($error_code, $error_message) = $dbunit->throws(':var := 100/1');
            ok(! $error_code, 'should not have error code');
            ok(! $error_message, 'should not have error message');
        }

    } else {
        {
            my $result = $dbunit->execute('SELECT NOW() INTO :var');
            ok($result->{var}, 'should have date');
        }
        {
            my $result = $dbunit->execute('
                SELECT 10 INTO :var1;
                :var2 := 360
            ');
            is($result->{var1}, 10, 'should have var1 bind variable value');
            is($result->{var2}, 360, 'should have var2 bind variable value');
        }
        {
            my ($error_code, $error_message) = $dbunit->throws(":var := dummy_fake_func('1')");
            ok ($error_code, 'should have error code');
            ok($error_message, 'should have error message');
        }
        {
            my ($error_code, $error_message) = $dbunit->throws(':var := 100/1');
            ok(! $error_code, 'should not have error code');
            ok(! $error_message, 'should not have error message');
        }
    }
    
    {    
    
        ok($dbunit->has_table('emp'), 'should have table emp');
        ok(! $dbunit->has_table('fake_emp'), 'should not have table fake_emp');

        ok($dbunit->has_view('emp_view'), 'should have emp_view');
        ok(! $dbunit->has_view('fake_emp'), 'should not have view fake_emp');

        ok($dbunit->has_column('emp', 'ename'), 'should have ename colunm on emp table');
        ok(! $dbunit->has_column('emp', 'ename2'), 'should not have ename2 colunm on emp table');
        
        ok($dbunit->has_columns('dept', ['deptno', 'dname', 'loc']), 'should have all emp columns');
        ok(! $dbunit->has_columns('dept', ['deptno', 'dname', 'loc1']), 'should not have all emp columns');
        ok($dbunit->failed_test_info, 'should have failure info');
        ok(! $dbunit->column_is_null('emp', 'empno'), 'should not have emono colunm nullabe');
        ok($dbunit->column_is_null('emp', 'sal'), 'should have sal colunm nullable');
        
        ok($dbunit->column_is_not_null('emp', 'empno'), 'should have column not nullable');
        ok(! $dbunit->column_is_not_null('emp', 'ename'), 'should have column nullable');
        
        
        ok($dbunit->column_type_is('emp', 'job', 'VARCHAR(20)'), 'should have job column as varchar(20)');
        
        ok($dbunit->column_type_is('emp', 'hiredate','date'), 'should have column as data type');
        
        ok($dbunit->column_default_is('lob_test', 'name', 'doc'), 'should have default value for column name');
        ok($dbunit->column_is_unique('emp', 'empno'), 'should have column unique');
        
        ok( $dbunit->has_pk('emp', 'empno'), 'should have pk on(empno)');
        ok( $dbunit->has_pk('emp'), 'table emp should have pk');
        
        ok(! $dbunit->has_pk('emp', 'ename'), 'should not have pk on ename');
        ok(! $dbunit->has_pk('bonus', ['ename']), 'should not have pk');
        ok($dbunit->has_pk('emp_project', ['empno', 'projno']), 'should have pk on emp_project');
        
        ok($dbunit->has_fk('emp', ['deptno'], 'dept'), 'should have fk on emp -> dept on deptno');
        ok($dbunit->has_fk('emp_project_details', ['empno', 'projno'], 'emp_project'), 'should have fk on emp_project_details -> emp_project on empno, projno');
        ok(! $dbunit->has_fk('emp', ['deptno1'], 'dept'), 'should not have fk on emp -> dept on deptno1');
        ok(! $dbunit->has_fk('emp', ['deptno'], 'dept2'), 'should not have fk on emp -> dept2 on deptno');
        
        ok($dbunit->has_index('emp_project_details', 'emp_project_details_idx'), 'should have index  emp_project_details_idx'); 
        
        ok($dbunit->has_index('emp_project_details', 'emp_project_details_idx', ['description','id']), 'should have index  emp_project_details_idx');
        
        ok(! $dbunit->has_index('emp_project_details', 'emp_project_details_idx', ['description']), 'should not detect index emp_project_details_idx(description)');
        ok(! $dbunit->has_index('emp_project_details', 'emp_project_details_idx1', ['description','id']), 'should not have index  emp_project_details_idx1');
        
        ok( $dbunit->index_is_unique('emp', 'emp_pk'), 'should have unique index');
        
        
        ok(!  $dbunit->index_is_primary('emp_project_details', 'emp_project_details_func'), 'should not have unique index');
        ok(!  $dbunit->index_is_unique('emp_project_details', 'emp_project_details_func'), 'should not have pk index');
        
        ok($dbunit->has_trigger('emp_project_details','aa_emp_project_details'), 'shold have trigger');
        
        ok(! $dbunit->has_trigger('emp_project_details1','aa_emp_project_details'), 'shold not have trigger for fake table');
        ok(! $dbunit->has_trigger('emp_project_details','aa_emp_project_details1'), 'shold not have fake trigger');
        
        ok($dbunit->trigger_is('emp_project_details','aa_emp_project_details', 'RETURN new;'), 'should match trigger body');
        ok(! $dbunit->trigger_is('emp_project_details','aa_emp_project_details', 'abc'), 'should not match trigger body');
        
        ok($dbunit->has_routine('test1'), 'should have function');
        ok(! $dbunit->has_routine('test1', ['OUT int', 'INOUT varchar', 'IN varchar', 'record']), 'should not have function');
        ok($dbunit->failed_test_info, 'should have failure info');
        ok(! $dbunit->has_sequence('emp_seq1'), 'should not have sequence');                
        
        SKIP: {
            if($connection->dbms_name eq 'PostgreSQL') {
                ok(! $dbunit->column_type_is('emp', 'job', 'fake'), 'should return db column definition');
                ok(! $dbunit->column_type_is('bonus', 'job', 'varcahar(30)'), 'should return db column definition');
                ok($dbunit->column_type_is('emp_project', 'projno', 'numeric'), 'should have column as numberic');
                ok($dbunit->index_is_primary('emp', 'emp_pk'), 'should have pk index');
                ok($dbunit->has_index('emp_project_details', 'emp_project_details_func' , "COALESCE(description, '1')"), 'should have index  emp_project_details_func -> COALESCE');
                ok($dbunit->has_index('emp_project_details', 'emp_project_details_func'), 'should have index  emp_project_details_func');
                ok($dbunit->trigger_is('emp_project_details','aa_emp_project_details', 'emp_project_details'), 'should match trigger body - function');
                ok($dbunit->has_routine('test1', ['OUT varchar', 'INOUT varchar', 'IN varchar', 'record']), 'should have function');
                ok($dbunit->has_sequence('emp_seq'), 'should have sequence');
            } else {
                if($connection->dbms_name eq 'MySQL') {
                    ok($dbunit->has_routine('test1', ['OUT varchar(100)', 'INOUT varchar(100)', 'IN varchar(100)']), 'should have routine');
                } else {
                    ok($dbunit->has_routine('test1', ['OUT varchar2', 'IN OUT varchar2', 'IN varchar2']), 'should have routine');
                }
                skip('not supported', 8);
            }
        }
    }
    
    
    
}
