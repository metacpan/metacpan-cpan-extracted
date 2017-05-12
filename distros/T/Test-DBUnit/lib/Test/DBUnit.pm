package Test::DBUnit;
use strict;
use warnings;

use vars qw($VERSION @EXPORT);
use base qw(Exporter);

use DBUnit ':all';
use DBIx::Connection;
use Carp 'confess';
use Sub::Uplevel qw(uplevel);
use Test::Builder;

$VERSION = '0.20';

@EXPORT = qw(
    expected_dataset_ok dataset_ok expected_xml_dataset_ok xml_dataset_ok
    reset_schema_ok populate_schema_ok reset_sequence_ok set_refresh_load_strategy
    set_insert_load_strategy test_connection set_test_connection add_test_connection test_dbh
    execute_ok throws_ok
    has_table hasnt_table
    has_view hasnt_view has_sequence hasnt_sequence
    has_column hasnt_column column_is_null column_is_not_null has_columns column_type_is
    column_default_is column_is_unique
    has_pk has_fk
    has_index index_is_unique index_is_primary index_is_type
    has_trigger trigger_is has_routine
);

=head1 NAME

Test::DBUnit - Database testing framework.

=head1 SYNOPSIS

    use DBIx::Connection;

    use Test::DBUnit connection_name => 'test';
    use Test::More tests => $tests;

    DBIx::Connection->new(
        name     => 'test',
        dsn      => $ENV{DB_TEST_CONNECTION},
        username => $ENV{DB_TEST_USERNAME},
        password => $ENV{DB_TEST_PASSWORD},
    );

    #or

    use Test::DBUnit;
    use Test::More tests => $tests;
    use DBI;

    my $dbh = DBI->connect(...);
    add_test_connection('test', $dbh)

    #or

    use Test::More;
    use Test::DBUnit dsn => 'dbi:Oracle:localhost:1521/ORACLE_INSTANCE', username => 'user', password => 'password';
    plan tests => $tests;

    my $connection = test_connection();
    my $dbh = test_dbh();

    reset_schema_ok('t/sql/create_schema.sql');

    populate_schema_ok('t/sql/create_schema.sql');

    xml_dataset_ok('test1');

    #you database operations here
    $connection->execute_statement("UPDATE ....");

    expected_xml_dataset_ok('test1');

    #or

    reset_sequence_ok('table1_seq1');

    dataset_ok(
        table1 => [column1 => 'x', column2 => 'y'],
        table1 => [column1 => 'x1_X', column2 => 'y1_X'],
        ...
        table2 => [column1 => 'x2, column2 => 'y2'],
        table2 => [column1 => 'x1_N', column2 => 'y1_N'],
    );

    #you database operations here
    $connection->execute_statement("UPDATE ....");

    expected_dataset_ok(
        table1 => [column1 => 'z', column2 => 'y'],
    )

    has_table('table1');
    has_columns('table1', [
    'column1', 'column2'
    ]);

    
    column_is_null('table1', 'column1');
    column_is_not_null('table1', 'columne2');
    column_type_is('table1', 'column1', 'varchar(20)');
    has_pk('table1', 'id');
    has_fk('table2', 'tab1_id', 'table1');
    has_index('table1', 'tab1_idx1', 'column1');
    index_is_unique('table1', tab_idx1');
    index_is_primary('tabl1', 'tab_idx_pk');
    index_is_type('tabl1', 'tab_idx_pk', 'btree');

    has_routine('approve_document', ['IN varchar', 'RETURN record']);


=head1 DESCRIPTION

Database testing framework that covers both black-box testing and clear-box(white-box) testing.

Black-box testing allows you to verify that your database data match expected set of values. 
This dataset comes either from tables, views, stored procedure/functions.

Clear-box testing focuses on existence database schema elements like tables, views, columns, indexes, triggers,
procedures, functions, constraints. Additionally  you can test particular characteristic of those object like
type, default value,  is unique, exceptions etc .

=head2 Managing test data

Database tests should giving you complete and fine grained control over the test data that is used.

    use Test::DBUnit dsn => $dsn, username => $username, password => $password;
    reset_schema_ok('t/sql/create_schema.sql');
    populate_schema_ok('t/sql/create_schema.sql');
    reset_sequence_ok('emp_seq');

=head2 Loading test data sets

Before you want to test your business logic it is essential to have repeatable snapshot of the data to be tested,
so this module allows you fill in/synchronize your database with the testing data.

    dataset_ok(
        emp => [ename => "john", deptno => "10", job => "project manager"],
        emp => [ename => "scott", deptno => "10", job => "project manager"],
        bonus => [ename => "scott", job => "project manager", sal => "20"],
    );
    or
    xml_dataset_ok('test1');
    t/test_unit.test1.xml #given that you testing module is t/test_unit.t
    <?xml version='1.0' encoding='UTF-8'?>
    <dataset load_strategy="INSERT_LOAD_STRATEGY">
        <emp empno="1" ename="scott" deptno="10" job="project manager" />
        <emp empno="2" ename="john"  deptno="10" job="engineer" />
        <bonus ename="scott" job="project manager" sal="20" />
    </dataset>

You may automatically create testing dataset or expected dataset using L<Test::DBUnit::Generator> module.

=head2 Getting connection to test database

    my $connection = test_connection();
    #business logic that change tested data comes here
    ....

=head2 Verifying test results

It can be useful to use data sets for checking the contents of a database after is has been modified by a test.
You may want to check the result of a update/insert/delete method or a stored procedure.

    expected_dataset_ok(
        emp   => [empno => "1", ename => "Scott", deptno => "10", job => "project manager"],
        emp   => [empno => "2", ename => "John",  deptno => "10", job => "engineer"],
        emp   => [empno => "3", ename => "Mark",  deptno => "10", job => "sales assistant"],
        bonus => [ename => "scott", job => "project manager", sal => "20"],
    );
    
    expected_dataset_ok(
        emp   => [empno => "1", ename => "Scott", deptno => "10", job => "project manager"],
        emp   => [empno => "2", ename => "John",  deptno => "10", job => "engineer"],
        emp   => [empno => "3", ename => "Mark",  deptno => "10", job => "sales assistant"],
        bonus => [ename => "scott", job => "project manager", sal => "20"],
        $description
    );
    
    or

    expected_xml_dataset_ok('test1');
    t/test_unit.test1-result.xml #given that you testing module is t/test_unit.t

    <?xml version='1.0' encoding='UTF-8'?>
    <dataset>
        <emp empno="1" ename="Scott" deptno="10" job="project manager" />
        <emp empno="2" ename="John"  deptno="10" job="engineer" />
        <emp empno="3" ename="Mark"  deptno="10" job="sales assistant" />
        <bonus ename="scott" job="project manager" sal="20" />
    </dataset>


=head3 Dynamic tests

You may want to check not just a particular value but range of values or perform complex condition against
database column's value, so that you can use callback. 

    expected_dataset_ok(
        emp   => [empno => "1", ename => "Scott", deptno => "10", job => "project manager"],
        emp   => [empno => "2", ename => "John",  deptno => "10", job => "engineer"],
        emp   => [empno => "3", ename => "Mark",  deptno => "10",
            job => sub {
                my $value = shift;
                !! ($value =~ /sales assistant/i);
            }
        ],
        bonus => [ename => "scott", job => "project manager", sal => "20"],
    );

    expected_dataset_ok(
        emp   => [empno => "1", ename => "Scott", deptno => "10", job => "project manager"],
        emp   => [empno => "2", ename => "John",  deptno => "10", job => "engineer"],
        emp   => [empno => "3", ename => "Mark",  deptno => "10",
            job => sub {
                my $value = shift;
                !! ($value =~ /sales assistant/i);
            }
        ],
        bonus => [ename => "scott", job => "project manager", sal => "20"],
        $description
    );

    or

    <?xml version='1.0' encoding='UTF-8'?>
    <dataset >
        <emp empno="1" ename="Scott" deptno="10" job="project manager" />
        <emp empno="2" ename="John"  deptno="10" job="engineer" />
        <emp empno="3" ename="Mark"  deptno="10" >
            <job><![CDATA[
                my $val = shift;
                !! ($val eq "sales assistant");
            ]]><job>
        <bonus ename="scott" job="project manager" sal="20" />
    </dataset>


=head2 Configuring the dataset load strategy

By default, datasets are loaded into the database using an insert load strategy.
This means that all data in the tables that are present in the dataset is deleted,
after which the test data records are inserted. Order in with all data is deleted
depends on reverse table occurrence in the dataset, however you may force order of
data by specifying empty table:

        table1 => [],  #this fore delete operation in occurrence order
        table1 => [col1 => 1, col2 => 'some data'],    
        or in xml file
        <table1 />
        <table1 col1="1" col2="some data"/>

In this strategy number of rows will be validated against datasets in (xml_)expexted_dataset_ok method.
Load strategy behavior is configurable,
it can be modified by calling:

    set_insert_load_strategy();
    or in XML
    <?xml version='1.0' encoding='UTF-8'?>
    <dataset load_strategy="INSERT_LOAD_STRATEGY">
        <emp empno="1" ename="Scott" deptno="10" job="project manager" />
        ....
    </dataset>

    set_refresh_load_strategy();
    or in XML

    <?xml version='1.0' encoding='UTF-8'?>
    <dataset load_strategy="REFRESH_LOAD_STRATEGY">
        <emp empno="1" ename="Scott" deptno="10" job="project manager" />
    </dataset>

The alternative to the insert load strategy is refresh load strategy.
In this case update on existing rows will take place or insert occurs if rows are missing.

=head3 Tests with multiple database instances.

You may need to test data from more then one database instance,
so that you have to specify connection against which tests will be performed
either by adding prefix to test methods, or by setting explicit test connection context.


    use Test::DBUnit connection_names => ['my_connection_1', 'my_connection_2'];
    my $dbh = DBI->connect($dsn_1, $username, $password);
    
    add_test_connection('my_connection_1', dbh => $dbh);
    # or
     my $connection = DBIx::Connection->new(
        name     => 'my_connection_2',
        dsn      => $dsn_2,
        username => $username,
        password => $password,
    );
    add_test_connection($connection);


    #set connection context by prefix
    my_connection_1_reset_schema_ok('t/sql/create_schema_1.sql');
    my_connection_1_populate_schema_ok('t/sql/create_schema_1.sql');

    my_connection_2_xml_dataset_ok('test1');
    ...
    my_connection_2_expected_xml_dataset_ok('test1');


    #set connection context explicitly.
    set_test_connection('my_connection_2');
    reset_schema_ok('t/sql/create_schema_2.sql');
    populate_schema_ok('t/sql/create_schema_2.sql');
    xml_dataset_ok('test1');

    expected_xml_dataset_ok('test1');


=head2 Working with sequences

You may use sequences or auto generated features, so this module allows you handle that.

    reset_sequence_ok('emp_seq');
    or for MySQL
    reset_sequence_ok('test_table_name')

The ALTER TABLE test_table_name AUTO_INCREMENT = 1 will be issued
Note that for MySQL reset sequence the test_table_name must be empty.

    or in XML
    <?xml version='1.0' encoding='UTF-8'?>
    <dataset reset_sequences="emp_seq, dept_seq">
        <emp empno="1" ename="Scott" deptno="10" job="project manager" />
        ....
    </dataset>

=head3 Sequence tests with Oracle

    t/sql/create_schema.sql
    CREATE SEQUENCE emp_seq;
    CREATE TABLE emp(
     empno      NUMBER NOT NULL,
     ename      VARCHAR2(10),
     job        VARCHAR2(20),
     mgr        NUMBER(4),
     hiredate   DATE,
     sal        NUMBER(7,2),
     comm       NUMBER(7,2),
     deptno     NUMBER(2),
     CONSTRAINT emp_pk PRIMARY KEY(empno),
     FOREIGN KEY (deptno) REFERENCES dept (deptno) 
    );
    CREATE OR REPLACE TRIGGER emp_autogen
    BEFORE INSERT ON emp FOR EACH ROW
    BEGIN
        IF :new.empno is null then
            SELECT emp_seq.nextval INTO :new.empno FROM dual;
        END IF;
    END;

    #unit test
    reset_sequence_ok('emp_seq');

    dataset_ok(
        emp => [ename => "John", deptno => "10", job => "project manager"],
        emp => [ename => "Scott", deptno => "10", job => "project manager"]
    );

    .... 

    expected_dataset_ok(
        emp => [empno => 1, ename => "John", deptno => "10", job => "project manager"],
        emp => [empno => 2, ename => "Scott", deptno => "10", job => "project manager"]
    )

=head3 Sequence tests with PostgreSQL

    t/sql/create_schema.sql
    CREATE SEQUENCE emp_seq;
    CREATE TABLE emp(
    empno      INT4 DEFAULT nextval('emp_seq') NOT NULL,
    ename      VARCHAR(10),
    job        VARCHAR(20),
    mgr        NUMERIC(4),
    hiredate   DATE,
    sal        NUMERIC(7,2),
    comm       NUMERIC(7,2),
    deptno     NUMERIC(2),
    CONSTRAINT emp_pk PRIMARY KEY(empno),
    FOREIGN KEY (deptno) REFERENCES dept (deptno) 
   );

    #unit test
    reset_sequence_ok('emp_seq');
    ....

=head3 Auto generated field values tests with MySQL

    t/sql/create_schema.sql
    CREATE TABLE emp(
    empno     MEDIUMINT AUTO_INCREMENT, 
    ename      VARCHAR(10),
    job        VARCHAR(20),
    mgr        NUMERIC(4),
    hiredate   DATE,
    sal        NUMERIC(7,2),
    comm       NUMERIC(7,2),
    deptno     NUMERIC(2),
    CONSTRAINT emp_pk PRIMARY KEY(empno),
    FOREIGN KEY (deptno) REFERENCES dept (empno) 
   );

    #unit test
    reset_sequence_ok('emp');

    dataset_ok(
        emp => [ename => "John", deptno => "10", job => "project manager"],
        emp => [ename => "Scott", deptno => "10", job => "project manager"]
    );

    .... 

    expected_dataset_ok(
        emp => [empno => 1, ename => "John", deptno => "10", job => "project manager"],
        emp => [empno => 2, ename => "Scott", deptno => "10", job => "project manager"]
    )

=head2 Working with LOBs

For handling very large datasets, the DB vendors provide the LOB (large object) data types.
You may use this features, and this module allows you test it.

=head3 LOBs tests with Oracle

Oracle BLOB data type that contains binary data with a maximum size of 4 gigabytes. 
It is advisable to store blob size in separate column to optimize fetch process.(doc_size)

    CREATE TABLE image(id NUMBER, name VARCHAR2(100), doc_size NUMBER, blob_content BLOB);

    dataset_ok(
        emp   => [empno => 1, ename => 'scott', deptno => 10],
        image  => [id => 1, name => 'Moon'
            blob_content => {file => 'data/chart1.jpg', size_column => 'doc_size'}
        ]
    );

    .....

    expected_dataset_ok(
        emp   => [empno => 1, ename => 'scott', deptno => 10],
        image  => [id => 1, name => 'Moon'
            blob_content => {file => 'data/chart2.jpg', size_column => 'doc_size'}
        ]
    );


=head3 LOBs tests with PostgreSQL

PostgreSQL has the large object facility, but in this case the tested table doesn't contain LOBs type
instead it keeps reference to lob_id, created by lo_creat PostgreSQL functions.
It requires storing blob size in separate column to be able to fetch blob.(doc_size)

    CREATE TABLE image(id NUMERIC, name VARCHAR(100), doc_size NUMERIC, blob_content oid)

    dataset_ok(
        emp   => [empno => 1, ename => 'scott', deptno => 10],
        image  => [id => 1, name => 'Moon'
            blob_content => {file => 'data/chart1.jpg', size_column => 'doc_size'}
        ]
    );


=head3 LOBs test with MySQL

In MySQL, binary LOBs are just table fields like any other types , so storing blob size is optional.

    CREATE TABLE lob_test(id NUMERIC, name VARCHAR(100), doc_size NUMERIC, blob_content LONGBLOB)

    dataset_ok(
        emp   => [empno => 1, ename => 'scott', deptno => 10],
        image  => [id => 1, name => 'Moon'
            blob_content => {file => 'data/chart1.jpg', size_column => 'doc_size'}
        ]
    );


=head2 Testing database stored procedures/functions

You may need to test execution of database stored procedures/functions. This module
allows you test both normal and exception execution path.


    execute_ok($plsql, $expected_values);
    throws_ok($sql, $errcode, $errmsg, $description);


=head2 Testing database schema objects

It can be useful to validate existence or characteristic of any schema objects including tables, columns,
indexes, constraints, etc ....
No once do the staging, life environments have discrepancy starting with missing indexes, constraints,
ending at difference in the table structures. This may lead too many problems  including
poor performance due to missing or wrong index type,
execution errors caused by incorrect columns data type,
logical errors by wrong or missing trigger/function.

It's felt that validation of schema objects significantly mitigate the risk of having out of sync state.
The following method allows you tests schema objects:
 

=head3 Table validation

Allows you testing existence/non-existence of the particular table.

    has_table('table1');
    hasnt_table('table1');


=head3 Table's columns validation

Focuses on testing existence/non existence column, additionally you may test column definition.

    has_columns('table1', [
        'column1', 'column2', 'columnN'
    ]);

    has_column('table1', 'column1');
    hasnt_column('table1', 'column1');
    column_is_null('table1', 'column1');
    column_is_not_null('table1', 'columne2');
    column_type_is('table1', 'column1', 'varchar(20)');


=head3 Constraints validation

Gives you options to validate primary, foreign keys.

    has_pk('table1', 'id');
    has_fk('table2', 'tab1_id', 'table1');

=head3 Indexes validation.

Allows you testing existence of the index, you  may also test index uniqueness, type.

    has_index('table1', 'tab1_idx1', 'column1');
    index_is_unique('table1', tab_idx1');
    index_is_primary('tabl1', 'tab_idx_pk');
    index_is_type('tabl1', 'tab_idx_pk', 'btree');


=head3 Functions/procedures validation

You may be interested in testing both existence of database functions/procedures
with the specified interface.

    has_routine('approve_document', ['IN varchar', 'RETURN record']);

You may automatically create schema objects tests using L<Test::DBUnit::Generator> module.


=head2 EXPORT

expected_data_set_ok
dataset_ok
expected_xml_dataset_ok
xml_dataset_ok
reset_schema_ok
populate_schema_ok
reset_sequence_ok
execute_ok
throws_ok
has_table
hasnt_table
has_view
hasnt_view
has_column
hasnt_column
has_columns
column_is_null
column_is_not_null
column_type_is
has_sequence
hasnt_sequence
has_pk
has_fk
has_index
index_is_unique
index_is_primary
index_is_type
has_trigger
trigger_is
has_routine
set_refresh_load_strategy
set_insert_load_strategy
add_test_connection
set_test_connection
test_connection
test_dbh
by default.


<connection_name>_(expected_data_set_ok | dataset_ok | expected_xml_dataset_ok | xml_dataset_ok |
            reset_schema_ok | populate_schema_ok | reset_sequence_ok | execute_ok | throws_ok |
            has_table | hasnt_table | has_view | hasnt_view | has_column | 
            hasnt_column | has_columns | column_is_null | column_is_not_null column_type_is |  
            has_pk | has_fk | has_index | index_is_unique | index_is_primary | index_is_type
            has_trigger | trigger_is | has_routine
            set_refresh_load_strategy | set_insert_load_strategy)
by connection_name tags.

=head2 METHODS

=over

=item connection_name

=cut

{
    
my $Tester = Test::Builder->new;
my $dbunit;
my $multiple_tests;
    sub import {
        my ($self, %args) = @_;
        if($args{connection_names}) {
            generate_connection_test_stubs($args{connection_names});
            $multiple_tests = 1;
            
        } elsif($args{connection_name}) {
            $dbunit = DBUnit->new(%args);
            
        } elsif(scalar(%args)) {
            eval {
                $dbunit = DBUnit->new(connection_name => 'test');
                _initialise_connection(%args);
            };
            if ($@) {
                my ($msg) = ($@ =~ /([^\n]+)/);
                $Tester->plan( skip_all => $msg);
            }
        } 
       $dbunit ||= DBUnit->new(connection_name => 'test');
       $self->export_to_level( 1, $self, $_ ) foreach @EXPORT;
    }


=item generate_connection_test_stubs

Generated test stubs on fly for passed in connection names.

=cut

sub generate_connection_test_stubs {
    my ($connections) = @_;
    for my $connection (@$connections) {
        for my $exp (@EXPORT[0 ..9]) {
            my $method_name = "${connection}_$exp";
            Abstract::Meta::Class::add_method(__PACKAGE__,
                $method_name, sub {
                    my $ory_connection_name = $dbunit->connection_name;
                    set_test_connection($connection);
                    my $method = __PACKAGE__->can($exp);
                    $method->(@_);
                    set_test_connection($ory_connection_name);
                }
            );
            push @EXPORT, $method_name;
        }
    }
    
}

=item reset_schema_ok

Tests database schema reset using sql file. Takes file name as parameter.

    use Test::More tests => $tests; 
    use Test::DBUnit dsn => $dsn, username => $username, password => $password;

    ...

    reset_schema_ok('t/sql/create_schema.sql');

=cut

    sub reset_schema_ok {
        my ($file_name) = @_;
        my $description = "should reset schema" . test_connection_context() . " (${file_name})";
        my $ok;
        eval {
            $dbunit->reset_schema($file_name);
            $ok = 1;
        };
        my $explanation = "";
        $explanation .= "\n" . $@ if $@;
        $Tester->ok($ok, $description );
        $Tester->diag($explanation) unless $ok;
        $ok;
    }


=item populate_schema_ok

Tests database schema population using sql file. Takes file name as parameter.

    use Test::More tests => $tests; 
    use Test::DBUnit dsn => $dsn, username => $username, password => $password;

    ...

    populate_schema_ok('t/sql/populate_schema.sql');

=cut


    sub populate_schema_ok {
        my ($file_name) = @_;
        my $description = "should populate schema". test_connection_context() ." (${file_name})";
        my $ok;
        eval {
            $dbunit->populate_schema($file_name);
            $ok = 1;
        };
        my $explanation = "";
        $explanation .= "\n" . $@ if $@;
        $Tester->ok( $ok, $description );
        $Tester->diag($explanation) unless $ok;
        $ok;
    }


=item reset_sequence_ok

Resets database sequence. Takes sequence name as parameter.

    use Test::More tests => $tests; 
    use Test::DBUnit dsn => $dsn, username => $username, password => $password;


    reset_sequnce('table_seq1');

=cut

    sub reset_sequence_ok {
        my ($sequence_name) = @_;
        my $description = "should reset sequence" . test_connection_context() . " ${sequence_name}";
        my $ok;
        eval {
            $dbunit->reset_sequence($sequence_name);
            $ok = 1;
        };
        my $explanation = "";
        $explanation .= "\n" . $@ if $@;
        $Tester->ok( $ok, $description );
        $Tester->diag($explanation) unless $ok;
        $ok;
    }


=item xml_dataset_ok

Tests database schema population/sync  to the content of the xml file.
Takes test unit name, that is used to resolve xml file name.
Xml file name that will be loaded is build as follow
<test_file>.<unit_name>.xml
for instance
the following invocation xml_dataset_ok('test1') from t/sub_dir/001_test.t file will
expect t/sub_dir/001_test.test1.xml file.

    <dataset load_strategy="INSERT_LOAD_STRATEGY" reset_sequences="emp_seq">
        <emp ename="scott" deptno="10" job="project manager" />
        <emp ename="john"  deptno="10" job="engineer" />
        <emp ename="mark"  deptno="10" job="sales assistant" />
        <bonus ename="scott" job="project manager" sal="20" />
    </dataset>


=cut

    sub xml_dataset_ok {
        my ($unit_name) = @_;
        my $xm_file = ($unit_name =~ /.xml$/i)
            ? $unit_name
            : _xml_test_file($unit_name) . ".xml";
        my $description = "should load dataset" . test_connection_context() . " (${xm_file})";
        my $ok;
        eval {
            $dbunit->xml_dataset($xm_file);
            $ok = 1;
        };
        my $explanation = "";
        $explanation .= "\n" . $@ if $@;
        $Tester->ok( $ok, $description );
        $Tester->diag($explanation) unless $ok;
        $ok;
    }


=item expected_xml_dataset_ok

Validates expected database loaded from xml file against database schema.
Takes test unit name, that is used to resolve xml file name.
Xml file name that will be loaded is build as follow
<test_file>.<unit_name>.xml unless you pass full xml file name.
for instance
the following invocation xml_dataset_ok('test1') from t/sub_dir/001_test.t file will
expect t/sub_dir/001_test.test1.xml file.

    <dataset load_strategy="INSERT_LOAD_STRATEGY" reset_sequences="emp_seq,dept_seq">
        <emp ename="Scott" deptno="10" job="project manager" />
        <emp ename="John"  deptno="10" job="engineer" />
        <emp ename="Mark"  deptno="10" job="sales assistant" />
        <bonus ename="Scott" job="project manager" sal="20" />
    </dataset>

=cut

    sub expected_xml_dataset_ok {
        my ($unit_name) = @_;
        my $xm_file = ($unit_name =~ /.xml$/i)
            ? $unit_name
            : _xml_test_file($unit_name) . "-result.xml";
        my $description = "should validate expected dataset" . test_connection_context() . "(${xm_file})";
        my $validation;
        my $ok;
        eval {
            $validation = $dbunit->expected_xml_dataset($xm_file);
            $ok = 1 unless $validation;
        };
        my $explanation = "";
        $explanation .= "\n" . $validation if $validation;
        $explanation .= "\n" . $@ if $@;
        $Tester->ok( $ok, $description );
        $Tester->diag($explanation) unless $ok;
        $ok;
    }


=item dataset_ok

Tests database schema population/sync to the passed in dataset.


    dataset_ok(
        $table => $row1,
        $table => $row2,
        $description
    );

    dataset_ok(
        table1 => [], #this deletes all data from table1 (DELETE FROM table1)
        table2 => [], #this deletes all data from table2 (DELETE FROM table2)
        table1 => [col1 => 'va1', col2 => 'val2'], #this insert or update depend on strategy
        table1 => [col1 => 'xval1', col2 => 'xval2'],
    )

=cut

    sub dataset_ok {
        my (@dataset) = @_;
        my $description = (@dataset % 2)
            ? pop(@dataset)
            : "should load dataset" . test_connection_context();
        my $ok;
        eval {
            $dbunit->dataset(@dataset);
            $ok = 1;
        };
        my $explanation = "";
        $explanation .= "\n" . $@ if $@;
        $Tester->ok($ok, $description );
        $Tester->diag($explanation) unless $ok;
        $ok;
    }


=item expected_dataset_ok

Validates database schema against passed in dataset.

    expected_dataset_ok(
        table1 => [col1 => 'va1', col2 => 'val2'], 
    )

    expected_dataset_ok(
        table1 => [col1 => 'va11', col2 => 'val2'],
        table1 => [col1 => 'va13', col2 => 'val4'],
        $desctiption
    );



=cut

    sub expected_dataset_ok {
        my (@dataset) = @_;
        my $description = (@dataset % 2)
            ? pop(@dataset)
            : "should validate expected dataset" . test_connection_context();
        my $validation;
        my $ok;
        eval {
            $validation = $dbunit->expected_dataset(@dataset);
            $ok = 1 unless $validation;
        };
        my $explanation = "";
        $explanation .= "\n" . $validation if $validation;
        $explanation .= "\n" . $@ if $@;
        $Tester->ok( $ok, $description );
        $Tester->diag($explanation) unless $ok;
        $ok;
    }



=item execute_ok

Tests execution of the plsql code against expected values.
    
    execute_ok($plsql, $expected_resultset);
    execute_ok($plsql, $expected_resultset, $bind_variables_definition);
    execute_ok($plsql, $expected_resultset, $bind_variables_definition, $description);

    execute_ok("SELECT my_function(NOW()) INTO :var", {var => 360});

=cut

    sub execute_ok {
        my ($plsql, $expected_resultset, $bind_varialbes_defintion, $description) = @_;
        $description ||=  "should have expected plsql data " . test_connection_context();
        my $result;
        eval {
            $result = $dbunit->execute($plsql, $bind_varialbes_defintion);
            
        };
        my $explanation = "";
        $explanation .= "\n" . $@ if $@;
        my $ok = Test::More::is_deeply($result, $expected_resultset ,$description);
        $Tester->diag($explanation) unless $ok;
        $ok;
    }


=item throws_ok

Tests database exceptions.

    throws_ok($sql, $errcode, $errmsg, $description);
    throws_ok($sql, $errcode, $errmsg);
    throws_ok($sql, $errmsg);
    throws_ok($sql, $errmsg, $description);
    throws_ok($sql, $errcode);

=cut

    sub throws_ok {
        my ($plsql, @args) = @_;
        my ($expexted_errcode)= map {($_ =~ /^\d+$/) ? ($_) : ()} @args;
        my $description = (@args == 3 || (! $expexted_errcode && @args == 2))? pop(@args) : '';
        my $expexted_errmsg = ($expexted_errcode && @args == 2) ? $args[-1] : $args[0];
        confess "error message shouldnt conatin error code"
            if($expexted_errmsg =~ /^\d+$/);
        
        my ($errcode, $errmsg);
        my $explanation = "";
        my $ok = 1;
        eval {
            ($errcode, $errmsg) = $dbunit->throws($plsql);
            if(defined $expexted_errcode) {
                $ok = $expexted_errcode eq $errcode;
            }
            if($ok && defined $expexted_errmsg) {
                $ok = ($errmsg =~ /$expexted_errmsg/i);
            }
            unless ($ok) {
                #warn $expexted_errmsg ,' ', $expexted_errcode;
                if ($expexted_errmsg || $expexted_errcode) {
                    $explanation = sprintf("caught: %s: %s\nexpected: %s: %s",
                        ($expexted_errcode  ? $errcode : ''),
                        ($expexted_errmsg ? $errmsg : ''),
                        ($expexted_errcode  ? $expexted_errcode : ''),
                        ($expexted_errmsg ? $expexted_errmsg : ''),
                    );
                }
            }
        };
    
        $explanation .= "\n" . $@ if $@;
        $Tester->ok( $ok, $description );
        $Tester->diag($explanation) unless $ok;
    }


=back

=head2 SCHEMA TESTS METHODS

This part focus on testing schema objects like table, column, index, triggers,
function, procedures.(clear database test)

API of the following methods partly was inspired by PgTap L<http://pgtap.projects.postgresql.org/>

=over

=item has_table

Tests if the specified table exists.

    has_table($schema, $table, $description);
    has_table($table, $description);
    has_table($table);

=cut

    sub has_table {
        my @args = @_;
        my ($table, $schema) = @args > 2 ? @args [1,0] : $args[0];
        my $description = (@args > 1)
            ? pop(@args)
            : "should have ${table} table" . test_connection_context();
        my $ok;
        eval {
            $ok = $dbunit->has_table($schema ? ($schema, $table) : ($table));
        };
        my $explanation = "";
        $explanation .= "\n" . $@ if $@;
        $Tester->ok($ok, $description);
        $Tester->diag($explanation) unless $ok;
        $ok;
    }


=item hasnt_table

Tests if the specified table doesn't exist.

    hasnt_table($schema, $table, $description);
    hasnt_table($table, $description);
    hasnt_table($table);

=cut

sub hasnt_table {
    my @args = @_;
    my ($table, $schema) = @args > 2 ? @args [1,0] : $args[0];
    my $description = (@args > 1)
        ? pop(@args)
        : "should not have table ${table} " . test_connection_context();
    my $ok;
    eval {
        $ok = ! $dbunit->has_table($schema ? ($schema, $table) : ($table));
    };
    my $explanation = "";
    $explanation .= "\n" . $@ if $@;
    $Tester->ok($ok, $description);
    $Tester->diag($explanation) unless $ok;
    $ok;
}


=item has_view

Tests if the specified view exists.

    has_view($schema, $view, $description);
    has_view($view, $description);
    has_view($view);

=cut

sub has_view {
    my @args = @_;
    my ($view, $schema) = @args > 2 ? @args [1,0] : $args[0];
    my $description = (@args > 1)
        ? pop(@args)
        : "should have view ${view} " . test_connection_context();
    my $ok;
    eval {
        $ok = $dbunit->has_view($schema ? ($schema, $view) : ($view));
    };
    my $explanation = "";
    $explanation .= "\n" . $@ if $@;
    $Tester->ok($ok, $description);
    $Tester->diag($explanation) unless $ok;
    $ok;
}


=item hasnt_view

Tests if the specified view exists.

    hasnt_view($schema, $view, $description);
    hasnt_view($view, $description);
    hasnt_view($view);

=cut

sub hasnt_view {
    my @args = @_;
    my ($view, $schema) = @args > 2 ? @args [1,0] : $args[0];
    my $description = (@args > 1)
        ? pop(@args)
        : "should have view ${view} " . test_connection_context();
    my $ok;
    eval {
        $ok = ! $dbunit->has_view($schema ? ($schema, $view) : ($view));
    };
    my $explanation = "";
    $explanation .= "\n" . $@ if $@;
    $Tester->ok($ok, $description);
    $Tester->diag($explanation) unless $ok;
    $ok;
}


=item has_column

Tests if the specified column exists in the given table.

    has_column($schema, $table, $column, $description);
    has_column($table, $column, $description);
    has_column($table, $column);

=cut

sub has_column {
    my @args = @_;
    my ($table, $column, $description, $schema) = @args == 4 ? @args [1,2,3,0] : @args;
    $description ||=  "should have column ${column} on table ${table} " . test_connection_context();
    my $ok;
    eval {
        $ok = $dbunit->has_column($schema ? ($schema, $table, $column) : ($table, $column));
    };
    my $explanation = "";
    $explanation .= "\n" . $@ if $@;
    $Tester->ok($ok, $description);
    $Tester->diag($explanation) unless $ok;
    $ok;

}


=item has_sequence

Tests if the specified table exists.

    has_sequence($schema, $sequence, $description);
    has_sequence($sequence, $description);
    has_sequence($sequence);

=cut

sub has_sequence {
    my @args = @_;
    my ($sequence, $schema) = @args > 2 ? @args [1,0] : $args[0];
    my $description = (@args > 1)
        ? pop(@args)
        : "should have ${sequence} sequence" . test_connection_context();
    my $ok;
    eval {
        $ok = $dbunit->has_sequence($schema ? ($schema, $sequence) : ($sequence));
    };
    my $explanation = "";
    $explanation .= "\n" . $@ if $@;
    $Tester->ok($ok, $description);
    $Tester->diag($explanation) unless $ok;
    $ok;
}


=item hasnt_sequence

Tests if the specified table doesn't exist.

    hasnt_sequence($schema, $sequence, $description);
    hasnt_sequence($sequence, $description);
    hasnt_sequence($sequence);

=cut

sub hasnt_sequence {
    my @args = @_;
    my ($sequence, $schema) = @args > 2 ? @args [1,0] : $args[0];
    my $description = (@args > 1)
        ? pop(@args)
        : "should not have ${sequence} sequence" . test_connection_context();
    my $ok;
    eval {
        $ok = ! $dbunit->has_sequence($schema ? ($schema, $sequence) : ($sequence));
    };
    my $explanation = "";
    $explanation .= "\n" . $@ if $@;
    $Tester->ok($ok, $description);
    $Tester->diag($explanation) unless $ok;
    $ok;
}


=item has_columns

Tests if all specified columns exist for given table.

    my $columms = ['id', 'name']
    
    has_columns($schema, $table, $columms);
    has_columns($schema, $table, $columms, $description);
    has_columns($table, $columms);
    has_columns($table, $columms, $description);

=cut

sub has_columns {
    my @args = @_;
    my $description = ((@args == 4) || (@args == 3 && ref($args[-2])))
        ? pop @args
        : 'should have columns';
    my $ok;
    eval {
        $ok = $dbunit->has_columns(@args);
    };
    my $explanation = $ok ? '' : $dbunit->failed_test_info;
    $explanation .= "\n" . $@ if $@;
    $Tester->ok($ok, $description);
    $Tester->diag($explanation) unless $ok;
    $ok;
}


=item hasnt_column

Tests if the specified column doesn't exist in the given table.

    hasnt_column($schema, $table, $column, $description);
    hasnt_column($table, $column, $description);
    hasnt_column($table, $column);

=cut

sub hasnt_column {
    my @args = @_;
    my ($table, $column, $description, $schema) = @args == 4 ? @args [1,2,3,0] : @args;
    $description ||=  "should not have column ${column} on ${table} table " . test_connection_context();
    my $ok;
    eval {
        $ok = ! $dbunit->has_column($schema ? ($schema, $table, $column) : ($table, $column));
    };
    my $explanation = "";
    $explanation .= "\n" . $@ if $@;
    $Tester->ok($ok, $description);
    $Tester->diag($explanation) unless $ok;
    $ok;
}



=item column_is_null

Tests if the specified column is nullable

    column_is_null($schema, $table, $columm, $description);
    column_is_null($table, $columm, $description);
    column_is_null($table, $columm);

=cut

sub column_is_null {
    my @args = @_;
    my ($table, $column, $description, $schema) = @args == 4 ? @args [1,2,3,0] : @args;
    $description ||=  "should have column ${column} nullable" . test_connection_context();
    my $ok;
    eval {
        $ok = $dbunit->column_is_null($schema ? ($schema, $table, $column) : ($table, $column));
    };
    my $explanation = "";
    $explanation .= "\n" . $@ if $@;
    $Tester->ok($ok, $description);
    $Tester->diag($explanation) unless $ok;
    $ok;
}


=item column_is_not_null

Tests if the specified column is not nullable

    column_is_not_null($schema, $table, $columm, $description);
    column_is_not_null($table, $columm, $description);
    column_is_not_null($table, $columm);

=cut

sub column_is_not_null {
    my @args = @_;
    my ($table, $column, $description, $schema) = @args == 4 ? @args [1,2,3,0] : @args;
    $description ||=  "should not have column ${column} nullable" . test_connection_context();
    my $ok;
    eval {
        $ok = $dbunit->column_is_not_null($schema ? ($schema, $table, $column) : ($table, $column));
    };
    my $explanation = "";
    $explanation .= "\n" . $@ if $@;
    $Tester->ok($ok, $description);
    $Tester->diag($explanation) unless $ok;
    $ok;
}


=item column_type_is

Tests if the specified column's type for given table matches underlying column type definition.

    column_type_is($schema, $table, $columm, $type);
    column_type_is($schema, $table, $columm, $type, $description);
    column_type_is($table, $columm, $type);

=cut

sub column_type_is {
    my @args = @_;
    my $description = @args == 5 ? pop @args : 'should validate colunmm type';
    my $ok;
    eval {
        $ok = $dbunit->column_type_is(@args);
    };
    my $explanation = $ok ? '' : $dbunit->failed_test_info;
    $explanation .= "\n" . $@ if $@;
    $Tester->ok($ok, $description);
    $Tester->diag($explanation) unless $ok;
    $ok;
}

=item column_default_is

Tests the specified default value matches database column definition.

    column_default_is_ok($schema, $table, $columm, $default);
    column_default_is_ok($schema, $table, $columm, $default, $description);
    column_default_is_ok($table, $columm, $default);

=cut

sub column_default_is {
    my @args = @_;
    my $description = @args == 5 ? pop @args : 'should check column default value';
    my $ok;
    eval {
        $ok = $dbunit->column_default_is(@args);
    };
    my $explanation = $ok ? '' : $dbunit->failed_test_info;
    $explanation .= "\n" . $@ if $@;
    $Tester->ok($ok, $description);
    $Tester->diag($explanation) unless $ok;
    $ok;
}


=item column_is_unique

    column_is_unique($table, $column);
    column_is_unique($schema, $table, $column);
    column_is_unique($schema, $table, $column, $description);

=cut

sub column_is_unique {
    my @args = @_;
    my $description = @args == 4 ? pop @args : 'should column be unique';
    my $ok;
    eval {
        $ok = $dbunit->column_is_unique(@args);
    };
    my $explanation = '';
    $explanation .= "\n" . $@ if $@;
    $Tester->ok($ok, $description);
    $Tester->diag($explanation) unless $ok;
    $ok;
}


=item has_pk

Tests existence of the primary key for given table with optionally 
specified columns that should be part of the primary key.

    has_pk($table);
    has_pk($schema, $table);
    has_pk($table, $column_or_columns);
    has_pk($schema, $table, $column_or_columns);


    has_pk($schema, $table, $description);
    has_pk($table, $column_or_columns, $description);
    has_pk($schema, $table, $column_or_columns, $description);

=cut

sub has_pk {
    my @args = @_;
    my $description = @args == 4 ? pop @args : 'should have pk';
    
    my $ok;
    eval {
        $description = ($args[-1] =~ /\s/) ?  pop @args : $description;
        $ok = $dbunit->has_pk(@args);
    };
    
    my $explanation = $ok ? '' : $dbunit->failed_test_info;
    $explanation .= "\n" . $@ if $@;
    $Tester->ok($ok, $description);
    $Tester->diag($explanation) unless $ok;
    $ok;
}


=item has_fk

Tests existence of the foreign key for given table and reference table
with the specified columns.

    has_fk($schema, $table, $columns, $referenced_schema, $referenced_table);
    has_fk($table, $columns, $referenced_table);
    has_fk($schema, $table, $columns, $referenced_schema, $referenced_table, $description);
    has_fk($table, $columns, $referenced_table, $description);

=cut

sub has_fk {
    my @args = @_;
    my $description = (@args == 6) ? pop @args : 'should have fk';
    my $ok;
    eval {
        $description = ($args[-1] =~ /\s/) ?  pop @args : $description;
        $ok = $dbunit->has_fk(@args);
    };
    my $explanation = $ok ? '' : $dbunit->failed_test_info;
    $explanation .= "\n" . $@ if $@;
    $Tester->ok($ok, $description);
    $Tester->diag($explanation) unless $ok;
    $ok;
}


=item has_index

Tests index existence for given table with the optionally specified columns.

    has_index($table, $index, $column_or_expressions);
    has_index($schema, $table, $index, $column_or_expressions);
    has_index($table, $index);
    has_index($schema, $table, $index);
    
    has_index($table, $index, $column_or_expressions, $desciption);
    has_index($schema, $table, $index, $column_or_expressions, $desciption);
    has_index($table, $index, $desciption);
    has_index($schema, $table, $index, $desciption);

=cut

sub has_index {
    my @args = @_;
    my $description = (@args == 5) ? pop @args : undef;
    my $ok;
    eval {
        $ok = $dbunit->has_index(@args);
        if(! $ok && ! $description && ! ref($args[-1])) {
            $description = pop @args;
            $ok = $dbunit->has_index(@args);
        }
    };
    $description ||= 'should have index';
    my $explanation = $ok ? '' : $dbunit->failed_test_info;
    $explanation .= "\n" . $@ if $@;
    $Tester->ok($ok, $description);
    $Tester->diag($explanation) unless $ok;
    $ok;
}


=item index_is_unique

    index_is_unique($schema, $table, $index);
    index_is_unique($table, $index);
    index_is_unique($schema, $table, $index, $description);
    index_is_unique($table, $index, $description);

=cut

sub index_is_unique {
    my @args = @_;
    my $description = (@args == 4) ? pop @args : undef;
    my $ok;
    eval {
        $ok = $dbunit->index_is_unique(@args);
        if(! $ok && ! $description && @args > 2 && ($args[-1] =~ /\s/)) {
            $description = pop @args;
            $ok = $dbunit->index_is_unique(@args);
        }
    };
    $description ||= 'should have unique index ';
    my $explanation = $ok ? '' : $dbunit->failed_test_info;
    $explanation .= "\n" . $@ if $@;
    $Tester->ok($ok, $description);
    $Tester->diag($explanation) unless $ok;
    $ok;
}


=item index_is_primary

    index_is_primary($schema, $table, $index);
    index_is_primary($table, $index);
    index_is_primary($schema, $table, $index, $description);
    index_is_primary$table, $index, $description);

=cut

sub index_is_primary {
    my @args = @_;
    my $description = (@args == 4) ? pop @args : undef;
    my $ok;
    eval {
        $ok = $dbunit->index_is_primary(@args);
        if(! $ok && ! $description && @args > 2 && ($args[-1] =~ /\s/)) {
            $description = pop @args;
            $ok = $dbunit->index_is_primary(@args);
        }

    };
    $description ||= 'should have primary_key index';
    my $explanation = $ok ? '' : $dbunit->failed_test_info;
    $explanation .= "\n" . $@ if $@;
    $Tester->ok($ok, $description);
    $Tester->diag($explanation) unless $ok;
    $ok;
}


=item index_is_type

Tests if the specified index's type matches defined index type

    index_is_type($schema, $table, $index, $type);
    index_is_type($table, $index, $type);
    index_is_type($schema, $table, $index, $type, $description);
    index_is_type($table, $index, $type, $description);

    type can be:
    - btree, bitmap, etc. - check you database vendor documentation.

=cut

sub index_is_type {
    my @args = @_;
    my $description = (@args == 5) ? pop @args : undef;
    my $ok;
    eval {
        $description = pop @args if (! $description && ($args[-1] =~ /\s/));
        $ok = $dbunit->index_is_type(@args);
    };
    $description ||= 'should validate index type';
    my $explanation = $ok ? '' : $dbunit->failed_test_info;
    $explanation .= "\n" . $@ if $@;
    $Tester->ok($ok, $description);
    $Tester->diag($explanation) unless $ok;
    $ok;
}


=item has_trigger

Tests if the specified trigger exists for the given table.

    has_trigger($schema, $table, $trigger);
    has_trigger($table, $trigger);
    has_trigger($schema, $table, $trigger, $description);
    has_trigger($table, $trigger, $description);

=cut

sub has_trigger {
    my @args = @_;
    my $description = (@args == 4) ? pop @args : undef;
    my $ok;
    eval {
        $description = pop @args if (! $description && ($args[-1] =~ /\s/));
        $ok = $dbunit->has_trigger(@args);
    };
    $description ||= 'should have trigger';
    my $explanation = $ok ? '' : $dbunit->failed_test_info;
    $explanation .= "\n" . $@ if $@;
    $Tester->ok($ok, $description);
    $Tester->diag($explanation) unless $ok;
    $ok;
}



=item trigger_is

Tests if the specified trigger body matches the trigger body (or function in case of postgresql)

    trigger_is($schema, $table, $trigger, $trigger_body);
    trigger_is($table, $trigger, $trigger_body);
    trigger_is($schema, $table, $trigger, $trigger_body, $description);
    trigger_is($table, $trigger, $trigger_body, $description);

=cut

sub trigger_is {
    my @args = @_;
    my $description = (@args == 5) ? pop @args : undef;
    my $ok;
    eval {
        $ok = $dbunit->trigger_is(@args);
        if (! $ok && ! $description && (@args == 4)) {
            $description = pop @args;
            $ok = $dbunit->trigger_is(@args);
        }
    };
    $description ||= 'should match trigger body';
    my $explanation = $ok ? '' : $dbunit->failed_test_info;
    $explanation .= "\n" . $@ if $@;
    $Tester->ok($ok, $description);
    $Tester->diag($explanation) unless $ok;
    $ok;
}


=item has_routine

Tests if the specified routine exists in database and optionally has expected arguments type.

    my $args = ['type1', 'type2', 'return_type'];
    or
    my $args = ['IN type1', 'OUT type2', 'type3'];
    or
    my $args = ['name1 type1', 'name2 type2', 'return type3'];
    or
    my $args = ['IN name1 type1', 'INOUT name2 type2', 'return type3'];

    has_routine($schema, $function);
    has_routine($function);
    has_routine($schema, $function, $args);
    has_routine($function, $args);

    has_routine($schema, $function, $description);
    has_routine($schema, $function, $args, $description);
    has_routine($function, $args, $description);
    has_routine($function, $description);

=cut

sub has_routine {
    my @args = @_;
    my $description = (@args == 4) ? pop @args : undef;
    my $ok;
    eval {
        $ok = $dbunit->has_routine(@args);
        if (! $ok && ! $description && ! ref($args[-1])) {
            $description = pop @args;
            $ok = $dbunit->has_routine(@args);
        }
    };
    $description ||= 'should have routine';
    my $explanation = $ok ? '' : $dbunit->failed_test_info;
    $explanation .= "\n" . $@ if $@;
    $Tester->ok($ok, $description);
    $Tester->diag($explanation) unless $ok;
    $ok;
    
}

=item _initialise_connection

Initializes default test connection

=cut

    my $connection;
    sub _initialise_connection {
        add_test_connection('test', @_);
    }


=item test_connection_context

Returns tested connection name,

=cut

sub test_connection_context {
    return '' unless $multiple_tests;
    "[" .$dbunit->connection_name . "]";
}

=item test_connection

Returns test connection object.

=cut

    sub test_connection {
        $connection = DBIx::Connection->connection($dbunit->connection_name);
    }
    

=item add_test_connection

Adds tests connection


    use Test::DBUnit;

    # or

    use Test::DBUnit connection_names => ['my_connection_name', 'my_connection_name1'];

    my $connection = DBIx::Connection->new(...);
    add_test_connection($connection);

    #or

    add_test_connection('my_connection_name', dsn =>  $dsn, username => $username, password => 'password');

    #or

    add_test_connection('my_connection_name', dbh => $dbh);


Note: By default there is "test" connection name, so if you would like to use only DBI then add $dbh as 'test' connection

    add_test_connection('test', dbh => $dbh);


=cut

    sub add_test_connection {
        my ($connection_, @args) = @_;
        if(ref($connection_)) {
            $connection = $connection_;
            $connection_ = $connection->name;
        }
        set_test_connection($connection_);
        if(@args) {
            $connection = DBIx::Connection->new(name => $connection_, @args);
        }
        
    }

=item set_test_connection

Sets test connection that will be tested.

=cut

    sub set_test_connection {
        my ($connection_name) = @_;
        $dbunit->set_connection_name($connection_name);
    }


=item test_dbh

Returns test database handler.

=cut

    sub test_dbh {
        test_connection()->dbh;
    }
    

=item set_insert_load_strategy

Sets insert as the load strategy

=cut

    sub set_insert_load_strategy {
        $dbunit->set_load_strategy(INSERT_LOAD_STRATEGY);
    }


=item set_refresh_load_strategy

Sets refresh as the load strategy

=cut

    sub set_refresh_load_strategy {
        $dbunit->set_load_strategy(REFRESH_LOAD_STRATEGY);
    }

}


=item _xml_test_file

Returns xml file prefix  to test

=cut

sub _xml_test_file {
    my ($unit_name) = @_;
    my $test_file = $0;
    $test_file =~ s/\.t/.$unit_name/;
    $test_file;
}



1;

__END__

=back

=head1 COPYRIGHT AND LICENSE

The Test::DBUnit module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 SEE ALSO

L<DBUnit>
L<Test::DBUnit::Generator>
L<DBIx::Connection>

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

=cut
