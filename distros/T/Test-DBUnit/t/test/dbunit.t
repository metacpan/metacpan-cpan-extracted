use strict;
use warnings;

use DBIx::Connection;
use Test::More tests => 93;
use Test::DBUnit connection_name => 'test';


SKIP: {
    skip('missing env varaibles DB_TEST_CONNECTION, DB_TEST_USERNAME DB_TEST_PASSWORD', 93)
        unless $ENV{DB_TEST_CONNECTION};
     my $connection = DBIx::Connection->new(
        name     => 'test',
        dsn      => $ENV{DB_TEST_CONNECTION},
        username => $ENV{DB_TEST_USERNAME},
        password => $ENV{DB_TEST_PASSWORD},
    );


    SKIP: {

        my $dbms_name  = $connection->dbms_name;
            skip('Tests are not prepared for ' . $dbms_name , 10)
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
        
            set_refresh_load_strategy;
            
        {
            dataset_ok(
                emp   => [empno => "1", ename => "scott", deptno => "10", job => "project manager"],
                emp   => [empno => "2", ename => "john",  deptno => "10", job => "engineer"],
                emp   => [empno => "3", ename => "mark",  deptno => "10", job => "sales assistant"],
                bonus => [ename => "scott", job => "project manager", sal => "20"],
                'should load my dataset'
            );

            $connection->execute_statement("UPDATE emp SET ename = ? WHERE empno = ?", 'Scott', 1);
            $connection->execute_statement("UPDATE emp SET ename = ? WHERE empno = ?", 'John', 2);
            $connection->execute_statement("UPDATE emp SET ename = ? WHERE empno = ?", 'Mark', 3);

            expected_dataset_ok(
                emp   => [empno => "1", ename => "Scott", deptno => "10", job => "project manager"],
                emp   => [empno => "2", ename => "John",  deptno => "10", job => "engineer"],
                emp   => [empno => "3", ename => "Mark",  deptno => "10", job => "sales assistant"],
                bonus => [ename => "scott", job => "project manager", sal => "20"],
                'should validate my dataset'
            )
        }
        
        my $schema = ($dbms_name eq 'PostgreSQL' ? 'public' : $ENV{DB_TEST_USERNAME});        
        SKIP: {
            skip('Tests are not prepared for ' . $dbms_name , 3) unless ($dbms_name  =~ /oracle|mysql|postgresql/i);
            
            if (lc($dbms_name) eq 'mysql') {
                skip('Tests are not prepared for ' . $dbms_name , 6);
            }
            
            execute_ok(":var := 360", {var => 360}, undef, 'should have expected plsql data');
            if ($dbms_name eq 'MySQL') {
                throws_ok(":var := fake_fumction('1')", 'fake_fumction does not exis', 'should catch expection');
                throws_ok(":var := fake_fumction('1')", 1305, 'fake_fumction does not exis', 'should catch expection');
                
                
            } elsif ($dbms_name eq 'Oracle') {
                throws_ok(":var := fake_fumction('1')", 'fake_fumction', 'should catch expection');
                throws_ok(":var := fake_fumction('1')", 6550, 'fake_fumction', 'should catch expection');
                has_sequence('emp_seq');
                has_sequence('emp_seq', 'should have sequence !');
                has_sequence($schema, 'emp_seq', 'should have sequence !');
                
                
            } elsif ($dbms_name eq 'PostgreSQL') {
                throws_ok(":var := fake_fumction('1')", 'fake_fumction', 'should catch expection');
                throws_ok(":var := fake_fumction('1')", 7, 'fake_fumction', 'should catch expection');
                
                has_sequence('emp_seq');
                has_sequence('emp_seq', 'should have sequence !');
                has_sequence($schema, 'emp_seq', 'should have sequence !');
                
            }
        }


        has_table('emp');
        has_table($schema, 'emp', 'should have table');
        has_table('emp', 'should have emp');
        
        hasnt_table('fake_emp');
        hasnt_table($schema, 'fake_emp', 'should nor have table');
        hasnt_table('fake_emp', 'should not have emp');
        
        has_view('emp_view');
        has_view($schema, 'emp_view', 'should have view');
        has_view('emp_view', 'should have emp_view');
        
        hasnt_view('fake_emp');
        hasnt_view($schema, 'fake_emp', 'should nor have view');
        hasnt_view('fake_emp', 'should not have emp');
        
        
        has_column($schema, 'emp', 'ename', 'should have column ename on emp table !');
        has_column('emp', 'ename', 'should have column ename on emp table !');
        has_column('emp', 'ename');
        
        hasnt_column($schema, 'emp', 'ename2', 'should not have column ename2 on emp table !');
        hasnt_column('emp', 'ename2', 'should not have column ename2 on emp table !');
        hasnt_column('emp', 'ename2');


        has_columns('dept', ['deptno', 'dname', 'loc'], 'should have all columns !');
        has_columns($schema, 'dept', ['deptno', 'dname', 'loc'], 'should have all columns (schema)');

        has_columns('dept', ['deptno', 'dname', 'loc']);
        has_columns($schema, 'dept', ['deptno', 'dname', 'loc']);
        
        column_is_null('emp', 'sal', 'should not have emono colunm nullabe');
        column_is_null('emp', 'ename', 'should not have emono colunm nullabe');
                
        column_is_not_null('emp', 'empno', 'should have column not nullable');
        column_is_not_null('emp', 'empno');

        column_type_is('emp', 'hiredate','date');
        column_type_is($schema, 'emp', 'hiredate','date');
        column_type_is($schema, 'emp', 'hiredate','date', 'should have column type');

        column_default_is('lob_test', 'name', 'doc');
        column_default_is($schema, 'lob_test', 'name', 'doc');
        column_default_is($schema, 'lob_test', 'name', 'doc', 'should have default value !');
        
        column_is_unique('emp', 'empno');
        column_is_unique($schema, 'emp', 'empno');
        column_is_unique($schema, 'emp', 'empno', 'should have column unique');


        has_pk('emp');
        has_pk($schema, 'emp');
        has_pk('emp', 'empno');
        has_pk($schema, 'emp', 'empno');


        has_pk($schema, 'emp', 'should have pk !');
        has_pk('emp', 'empno', 'should have pk (schema)!');
        has_pk($schema, 'emp', 'empno', 'should have pk (schema)!');

        has_fk('emp', ['deptno'], 'dept');
        has_fk('emp_project_details', ['empno', 'projno'], 'emp_project', 'should have fk emp_project_details -> emp_project');

        has_fk($schema, 'emp', ['deptno'], $schema, 'dept');
        has_fk($schema, 'emp_project_details', ['empno', 'projno'], $schema, 'emp_project', 'should have fk emp_project_details -> emp_project(schema)');
        
        
        has_index('emp_project_details', 'emp_project_details_idx');
        has_index('emp_project_details', 'emp_project_details_idx', 'should have index !');
        has_index('emp_project_details', 'emp_project_details_idx', ['description','id']);
        has_index('emp_project_details', 'emp_project_details_idx', ['description','id'], 'should have index (columns)!');

        has_index($schema, 'emp_project_details', 'emp_project_details_idx', ['description','id']);
        has_index($schema, 'emp_project_details', 'emp_project_details_idx', ['description','id'], 'should have index !');
        has_index($schema, 'emp_project_details', 'emp_project_details_idx');
        has_index($schema, 'emp_project_details', 'emp_project_details_idx', 'should have index !');
        
        index_is_unique('emp', 'emp_pk');
        index_is_unique('emp', 'emp_pk', 'should have index unique !');

        index_is_unique($schema, 'emp', 'emp_pk');
        index_is_unique($schema, 'emp', 'emp_pk', 'should have index unique !');
        
        SKIP: {

        skip('not suppored', 4) if($dbms_name eq 'MySQL');
        index_is_primary('emp', 'emp_pk');
        index_is_primary('emp', 'emp_pk', 'should have pk index !');

        index_is_primary($schema, 'emp', 'emp_pk');
        index_is_primary($schema, 'emp', 'emp_pk', 'should have pk index !');
        }
        
        has_trigger('emp_project_details','aa_emp_project_details');
        has_trigger('emp_project_details','aa_emp_project_details', 'shold have trigger !');
        
        has_trigger($schema, 'emp_project_details','aa_emp_project_details');
        has_trigger($schema, 'emp_project_details','aa_emp_project_details', 'shold have trigger !');
        
        
        trigger_is('emp_project_details','aa_emp_project_details', 'RETURN new;');
        trigger_is('emp_project_details','aa_emp_project_details', 'RETURN new;', 'should match trigger body !');
        
        trigger_is($schema, 'emp_project_details','aa_emp_project_details', 'RETURN new;');
        trigger_is($schema, 'emp_project_details','aa_emp_project_details', 'RETURN new;', 'should match trigger body !');
        
        has_routine('test1');
        has_routine('test1', 'should have procedure test1 !');
        has_routine($schema, 'test1');
        has_routine($schema, 'test1', 'should have procedure test1 !');

        hasnt_sequence('emp_seq1');
        hasnt_sequence('emp_seq1', 'should have sequence !');
        hasnt_sequence($schema, 'emp_seq1', 'should have sequence !');
        
        
        set_insert_load_strategy;
        SKIP: {
            skip('Tests are not prepared for ' . $dbms_name , 3)
                if($dbms_name ne 'PostgreSQL' && $dbms_name ne 'Oracle' && $dbms_name ne 'MySQL');
            
            $connection->execute_statement("DELETE FROM emp");
            reset_sequence_ok($dbms_name ne 'MySQL' ? 'emp_seq' : 'emp');
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