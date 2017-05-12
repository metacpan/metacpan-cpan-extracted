use warnings;
use strict;

use Test::More tests => 19;
use Persistence::Entity ':all';
use SQL::Entity::Condition;
use Persistence::Meta::Injection;

my $class;

BEGIN {
    $class = 'Persistence::Meta::XML';
    use_ok($class);
}

{
    my $meta = $class->new();
    isa_ok($meta, $class);
    $meta->set_injection(Persistence::Meta::Injection->new);    
    my $entities = $meta->injection->entities;
    my $xml =  $meta->entity_xml_handler;
    
    {
        my $xml_content = '<?xml version="1.0" encoding="UTF-8"?>
    <entity name="emp" alias="e">
        <primary_key>empno</primary_key>
        <indexes>
            <index name="emp_idx_empno" hint="INDEX_ASC(e emp_idx_empno)">
                <index_column>empno</index_column>
            </index>
            <index name="emp_idx_ename">
                <index_column>ename</index_column>
            </index>
        </indexes>
        <columns>
            <column name="empno" />
            <column name="ename" unique="1" />
            <column name="job" />
            <column name="deptno" />
        </columns>
        <subquery_columns>
            <subquery_column name="dname" entity="dept" />
        </subquery_columns>
        <to_one_relationships>
            <relationship target_entity="dept">
                <join_column>deptno</join_column>
                <condition operand1="sql_column:dept.deptno" operator="=" operand2="sql_column:emp.deptno"  />
            </relationship>
        </to_one_relationships>
    </entity>
    ';
    my $entity = $xml->parse_string($xml_content);
    $meta->injection->entity('emp', $entity);
    
    is_deeply($entity,  Persistence::Entity->new(
        name        => 'emp',
        alias       => 'e',
        primary_key => ['empno'],
        columns               => [
            sql_column(name => 'ename', unique => 1),
            sql_column(name => 'empno'),
            sql_column(name => 'job'),
            sql_column(name => 'deptno')
        ],
        indexes     => [
            sql_index(name => 'emp_idx_empno', columns => ['empno'], hint => "INDEX_ASC(e emp_idx_empno)"),
            sql_index(name => 'emp_idx_ename', columns => ['ename']),
        ],
    
    ), 'should deserialise xml into emp entity object');
    
    my $entities_subquery_columns = $meta->injection->_entities_subquery_columns;
    is_deeply($entities_subquery_columns, {emp  => [{entity => 'dept', name => 'dname'}]}, 'should have subqueries');
    
    }
    
    
    {
        my $xml_content = '<?xml version="1.0" encoding="UTF-8"?>
    <entity name="dept" alias="d">
        <primary_key>deptno</primary_key>
        <columns>
            <column name="deptno" />
            <column name="dname"  unique="1" />
            <column name="loc" />
        </columns>
    </entity>
    ';
    
    my $entity = $xml->parse_string($xml_content);
    is_deeply($entity,  Persistence::Entity->new(
        name        => 'dept',
        alias       => 'd',
        primary_key => ['deptno'],
        columns               => [
            sql_column(name => 'dname', unique => 1),
            sql_column(name => 'deptno'),
            sql_column(name => 'loc'),
        ],
    ), 'should deserialise xml into dept entity object');
    $meta->injection->entity('dept', $entity);
    my $entities_subquery_columns = $meta->injection->_entities_subquery_columns;
    is_deeply($entities_subquery_columns, {emp  => [{entity => 'dept', name => 'dname'}], dept => []}, 'should have subqueries');
    }
    
    ok($meta->injection->entity_column('emp', 'empno'), 'should have entity column');
    eval {$meta->injection->entity_column('emp', 'empno2')};
    like($@, qr{unknown column}, 'should catch unknown column exception');
    eval {$meta->injection->entity_column('emp1', 'empno2')};
    like($@, qr{unknown entity}, 'should catch unknown entity exception');
    
    
    {   
        $meta->injection->_initialise_subquery_columns();
        my $emp = $meta->injection->entity('emp');
        my $dept = $meta->injection->entity('dept');
        is_deeply($emp, Persistence::Entity->new(
        name                  => 'emp',
        alias                 => 'e',
        primary_key           => ['empno'],
        subquery_columns      => [$dept->column('dname')],
        columns               => [
            sql_column(name => 'ename', unique => 1),
            sql_column(name => 'empno'),
            sql_column(name => 'job'),
            sql_column(name => 'deptno')
        ],
        indexes                 => [
            sql_index(name => 'emp_idx_empno', columns => ['empno'], hint => "INDEX_ASC(e emp_idx_empno)"),
            sql_index(name => 'emp_idx_ename', columns => ['ename']),
        ],), 'should have subquery on emp entity');
    }
    
    
    {
        $meta->injection->_initialise_to_one_relationships();
        $meta->injection->_initialise_to_many_relationships();
        my $emp = $meta->injection->entity('emp');
        my $dept = $meta->injection->entity('dept');
        my $cond = sql_cond($dept->column('deptno'), '=', $emp->column('deptno'));
        $cond->conditions;
        is_deeply($emp, Persistence::Entity->new(
        name                  => 'emp',
        alias                 => 'e',
        primary_key           => ['empno'],
        subquery_columns      => [$dept->column('dname')],
        columns               => [
            sql_column(name => 'ename', unique => 1),
            sql_column(name => 'empno'),
            sql_column(name => 'job'),
            sql_column(name => 'deptno')
        ],
        to_one_relationships    =>  [
            sql_relationship(target_entity => $dept, join_columns => ['deptno'], condition => $cond)
        ],
        indexes                 => [
            sql_index(name => 'emp_idx_empno', columns => ['empno'], hint => "INDEX_ASC(e emp_idx_empno)"),
            sql_index(name => 'emp_idx_ename', columns => ['ename']),
        ],), 'should have subquery on emp entity');
     
    }

    package Employee;
    use Abstract::Meta::Class ':all';
    
    has '$.id';
    has '$.name';
    has '$.job';
    has '$.dept' => (associated_class => 'Department');
    
    
    package Department;
    use Abstract::Meta::Class ':all';
    
    has '$.id';
    has '$.name';
    has '$.location';
    has '@.employees' => (associated_class => 'Employee');

    $xml = $meta->orm_xml_handler;
    $meta->injection->  set_entity_manager(Persistence::Entity::Manager->new(name => 'test', connection_name => 'test'));    
        my $xml_content = '<?xml version="1.0" encoding="UTF-8"?>
    <orm entity="emp"  class="Employee" >
        <column name="empno" attribute="id" />
        <column name="ename" attribute="name" />
        <column name="job" attribute="job" />
        <to_one_relationship  name="dept" attribute="dept" fetch_method="LAZY" cascade="ALL"/>
    </orm>
    ';
    
    $xml->parse_string($xml_content);
    $meta->injection->load_persistence_context($meta);
    my $orm = $meta->injection->entity_manager->find_entity_mappings('Employee');
    ::isa_ok($orm, 'Persistence::ORM');
    ::isa_ok($orm->_column('ename'), 'Persistence::Attribute', 'should have ename column mapping');
    ::isa_ok($orm->_column('empno'), 'Persistence::Attribute', 'should have empno column mapping');
    ::isa_ok($orm->_column('job'), 'Persistence::Attribute', 'should have job column mapping');

}



{

    my $meta = $class->new(persistence_dir => 't/meta/xml/');
    $meta->set_injection(Persistence::Meta::Injection->new);        
    my $xml =  $meta->persistence_xml_handler;
    {
        my $xml_content = '<?xml version="1.0" encoding="UTF-8"?>
    <persistence name="test"  connection_name="test" >
        <entities>
            <entity_file  file="emp.xml"   />
            <entity_file  file="dept.xml" />
        </entities>
        <mapping_rules>
            <orm_file file="Employee.xml"    />
        </mapping_rules>
    </persistence>
    ';
    
    $xml->parse_string($xml_content);
    my $manager = $meta->injection->load_persistence_context($meta);
    isa_ok($manager, 'Persistence::Entity::Manager');
    my $emp = $manager->entity('emp');
    isa_ok($emp, 'Persistence::Entity');
    my $dept = $manager->entity('dept');
    isa_ok($dept, 'Persistence::Entity');
    }
 
    my $entity_manager = $meta->inject('persistence.xml');
    isa_ok($entity_manager, 'Persistence::Entity::Manager');
    
}