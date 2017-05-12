use strict;
use warnings;

use Test::More tests => 25;
use Test::DBUnit connection_name => 'test';

my $class;
my $fetch_counter;
BEGIN {
    $class = 'Persistence::Relationship::OneToMany';
    use_ok($class, ':all');
    use_ok('Persistence::Entity::Manager');
    use_ok('Persistence::ORM', ':all');
    use_ok('Persistence::Entity', ':all');
}

my $entity_manager = Persistence::Entity::Manager->new(name => 'my_manager', connection_name => 'test');

{
    my $emp_entity = Persistence::Entity->new(
        name    => 'emp',
        alias   => 'ep',
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
        alias   => 'dt',
        primary_key => ['deptno'],
        columns => [
            sql_column(name => 'deptno'),
            sql_column(name => 'dname'),
            sql_column(name => 'loc')
        ],
        to_many_relationships => [sql_relationship(target_entity => $emp_entity, join_columns => ['deptno'], order_by => 'deptno, empno')]
    );

    $entity_manager->add_entities($dept_entity, $emp_entity);
}


{
    package Employee;
    
    use Abstract::Meta::Class ':all';
    use Persistence::Entity ':all';
    use Persistence::ORM ':all';
    
    entity 'emp';
    column empno=> has('$.id');
    column ename => has('$.name');
    column job => has '$.job';
    trigger (on_fetch => sub {$fetch_counter++;});
}


{
    package Department;
    
    use Abstract::Meta::Class ':all';
    use Persistence::Entity ':all';
    use Persistence::ORM ':all';
    
    entity 'dept';
    column deptno => has('$.id');
    column dname => has('$.name');
    column loc   => has('$.location');
    
    my $relation = one_to_many 'emp' => (
        attribute    => has('@.employees' => (associated_class => 'Employee')),
        fetch_method => EAGER,
        cascade      => ALL,
    );
    ::is_deeply([$class->insertable_to_many_relations('Department')], [$relation], 'should have insertable relations');
    ::is_deeply([$class->updatable_to_many_relations('Department')],  [$relation],  'should have updatable relations');
    ::is_deeply([$class->deleteable_to_many_relations('Department')], [$relation], 'should have deleteable relations');
}


{
    package HODepartment;
    
    use Abstract::Meta::Class ':all';
    use Persistence::Entity ':all';
    use Persistence::ORM ':all';

    entity 'dept';
    column deptno => has('$.id');
    column dname => has('$.name');
    column loc => has('$.location');
    
    my $relation = one_to_many 'emp' => (
        attribute    => has('@.employees' => (associated_class => 'Employee', item_accessor => 'employee')),
        fetch_method => LAZY,
        cascade      => ON_INSERT,
        );

    
    ::is_deeply([$class->insertable_to_many_relations('HODepartment')], [$relation], 'should have insertable relations');
    ::ok(! $class->updatable_to_many_relations('HODepartment'), 'should not have updatable relations');
    ::ok(! $class->deleteable_to_many_relations('HODepartment'), 'should not have deleteable relations');
}


SKIP: {
    
    ::skip('missing env varaibles DB_TEST_CONNECTION, DB_TEST_USERNAME DB_TEST_PASSWORD', 15)
      unless $ENV{DB_TEST_CONNECTION};

    my $connection = DBIx::Connection->new(
      name     => 'test',
      dsn      => $ENV{DB_TEST_CONNECTION},
      username => $ENV{DB_TEST_USERNAME},
      password => $ENV{DB_TEST_PASSWORD},
    ); 


    reset_schema_ok("t/sql/". $connection->dbms_name . "/create_schema.sql");
    
    xml_dataset_ok('init');
    {
        my ($dept) = $entity_manager->find(dept => 'Department', name => 'dept3');
        #eager test
        my $employees = $dept->{'@.employees'};
        is_deeply($employees, [
                Employee->new(id => 1, name => 'emp1', job => undef),
                Employee->new(id => 4, name => 'emp4', job => undef),
        ], 'should eagerly retrive relation data');
    }

    {   #lazy fetch
        my ($dept) = $entity_manager->find(dept => 'HODepartment', name => 'dept3');
        {
            my $employees = $dept->{'@.employees'};
            is_deeply($employees, undef, 'should not retrive data until needed');
        }
    
        {
            my $lazy_counter = $fetch_counter;
            my $employees = $dept->employees;
            is_deeply($employees, [
                Employee->new(id => 1, name => 'emp1', job => undef),
                Employee->new(id => 4, name => 'emp4', job => undef),
            ], 'should lazily retrive relation data');
            $dept->employees;
            
            is($fetch_counter - $lazy_counter, @$employees, 'should fetch occur only once');
            ok($entity_manager->refersh($dept), 'should refresh object');
            {
                my $lazy_counter = $fetch_counter;
                my $employees = $dept->employees;
                is_deeply($employees, [
                    Employee->new(id => 1, name => 'emp1', job => undef),
                    Employee->new(id => 4, name => 'emp4', job => undef),
                ], 'should lazily retrive relation data');
                $dept->employees;
                is($dept->employee(0), $employees->[0], 'should have the same employee');
                is($fetch_counter, 6, 'should lazily retrive relation data after refresh object');
            }
        }
    }
    
    
    #cascade on insert
    {
        my $dept =  new HODepartment(
            id         => '50',
            name       => 'dept50',
            location   => 'loc50',
            employees => [
                Employee->new(id => 21, name => 'emp21', job => undef),
                Employee->new(id => 22, name => 'emp22', job => 'manager')
            ]
        );
        $entity_manager->insert($dept);
    }
    
    expected_xml_dataset_ok('insert');
    

    xml_dataset_ok('init');

    #cascade on update 
    {
        my ($dept) = $entity_manager->find(dept => 'Department', name => 'dept3');
        $dept->set_location('loc33');
        my @employees = $dept->employees;
        $employees[0]->set_job('sales assistant');
        $dept->add_employees(Employee->new(id => 22, name => 'emp22', job => 'manager'));
        $entity_manager->update($dept);
    }
    expected_xml_dataset_ok('update');
    
    
    
    xml_dataset_ok('init');
    
    #cascade on delete
    {
        my ($dept) = $entity_manager->find(dept => 'Department', name => 'dept3');
        $entity_manager->delete($dept);
        
    }
    expected_xml_dataset_ok('delete');
}