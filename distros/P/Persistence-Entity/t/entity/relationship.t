
use strict;
use warnings;

use Test::More tests => 13;
use Test::DBUnit connection_name => 'test';


BEGIN {
    use_ok('Persistence::Entity::Manager');
    use_ok('Persistence::Entity', ':all');
}


my $emp_entity = Persistence::Entity->new(
    name    => 'emp',
    alias   => 'ur',
    primary_key => ['empno'],
    columns => [
        sql_column(name => 'empno'),
        sql_column(name => 'ename', unique => 1),
        sql_column(name => 'job'),
        sql_column(name => 'deptno'),
    ],
);

my $dept_entity = Persistence::Entity->new(
    name    => 'dept',
    alias   => 'dp',
    primary_key => ['deptno'],
    columns => [
        sql_column(name => 'deptno'),
        sql_column(name => 'dname', unique => 1),
        sql_column(name => 'loc')
    ],
    to_many_relationships => [sql_relationship(target_entity => $emp_entity, join_columns => ['deptno'], order_by => 'deptno, empno')]
);


{
    my $entity_manager = Persistence::Entity::Manager->new(name => 'my_manager', connection_name => 'test');
    $entity_manager->add_entities($dept_entity, $emp_entity);
}

{
    eval {
        $dept_entity->relationship_insert('fake_relation');
    };
    ok($@, 'should catch unknown relation error - insert');

    eval {
        $dept_entity->relationship_merge('fake_relation');
    };
    ok($@, 'should catch unknown relation error - merge');

    eval {
        $dept_entity->relationship_delete('fake_relation');
    };
    ok($@, 'should catch unknown relation error - delete');

    
}


SKIP: {
    
    ::skip('missing env varaibles DB_TEST_CONNECTION, DB_TEST_USERNAME DB_TEST_PASSWORD', 8)
      unless $ENV{DB_TEST_CONNECTION};

    my $connection = DBIx::Connection->new(
      name     => 'test',
      dsn      => $ENV{DB_TEST_CONNECTION},
      username => $ENV{DB_TEST_USERNAME},
      password => $ENV{DB_TEST_PASSWORD},
    ); 


    eval {
        $dept_entity->relationship_merge('emp', {loc => 'dept1'} , [{empno => 11, ename => 'emp11'}, {empno => 12, ename => 'emp12'}]);
    };
    like($@, qr{primary key values}, 'should catch cant get primary key values error - merge');

    eval {
        $dept_entity->relationship_delete('emp', {loc => 'dept1'} , [{empno => 11, ename => 'emp11'}, {empno => 12, ename => 'emp12'}]);
    };
    like($@, qr{primary key values}, 'should catch cant get primary key values error - delete');


    SKIP: {

        my $dbms_name  = $connection->dbms_name;
            skip('Tests are not prepared for ' . $dbms_name , 7)
                unless -d "t/sql/". $connection->dbms_name;
                
        reset_schema_ok("t/sql/". $connection->dbms_name . "/create_schema.sql");
        
        xml_dataset_ok('init');
        
        {
            my @emp = $dept_entity->relationship_query('emp', undef => undef, dname => 'dept3');
            ::is_deeply(\@emp, [
                {the_rowid => 1, deptno => 3, ename => 'emp1', 'job' => undef, empno => 1},
                {the_rowid => 3, deptno => 3, ename => 'emp3', 'job' => undef, empno => 3},
                ], 'should fetch relationship rows');
        }
        
        $dept_entity->relationship_insert('emp', {dname => 'dept1'} , {empno => 11, ename => 'emp11'}, {empno => 12, ename => 'emp12'});
        expected_xml_dataset_ok('insert');
    
        $dept_entity->relationship_merge('emp', {dname => 'dept3'} , {empno => 13, ename => 'emp13'}, {empno => 1, ename => 'emp1', job => 'sales assistant'});
        expected_xml_dataset_ok('merge');
        
        $dept_entity->relationship_delete('emp', {dname => 'dept1'}, {ename => 'emp11'}, {ename => 'emp12'});
        expected_xml_dataset_ok('delete');
    }
}

