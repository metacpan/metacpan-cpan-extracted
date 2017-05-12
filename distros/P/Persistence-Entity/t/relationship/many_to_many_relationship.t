use strict;
use warnings;

use Test::More tests => 15;
use Test::DBUnit connection_name => 'test';

my $class;
my $fetch_counter;

BEGIN {
    $class = 'Persistence::Relationship::ManyToMany';
    use_ok($class, ':all');
    use_ok('Persistence::Entity::Manager');
    use_ok('Persistence::ValueGenerator::TableGenerator', ':all');
    use_ok('Persistence::ORM', ':all');
    use_ok('Persistence::Entity', ':all');
}

my $entity_manager = Persistence::Entity::Manager->new(name => 'my_manager', connection_name => 'test');

table_generator 'project_gen' => (
    entity_manager_name      => "my_manager",
    table                    => 'seq_generator',
    primary_key_column_name  => 'pk_column',
    primary_key_column_value => 'projno',
    value_column             => 'value_column',
    allocation_size          =>  5,
);

table_generator 'emp_gen' => (
    entity_manager_name      => "my_manager",
    table                    => 'seq_generator',
    primary_key_column_name  => 'pk_column',
    primary_key_column_value => 'empno',
    value_column             => 'value_column',
    allocation_size          =>  5,
);

{
    my $emp_project_entity = Persistence::Entity->new(
        name    => 'emp_project',
        alias   => 'ep',
        primary_key => ['projno', 'empno'],
        columns => [
            sql_column(name => 'projno'),
            sql_column(name => 'empno'),
            sql_column(name => 'leader'),
        ],
    );

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
        value_generators => {empno => 'emp_gen'}, 
        to_many_relationships => [
            sql_relationship(target_entity => $emp_project_entity,
            join_columns => ['empno'], order_by => 'empno, projno')
        ]
    );

    my $project_entity = Persistence::Entity->new(
        name    => 'project',
        alias   => 'pr',
        primary_key => ['projno'],
        columns => [
            sql_column(name => 'projno'),
            sql_column(name => 'name', unique => 1),
        ],
        value_generators => {projno => 'project_gen'},
        to_many_relationships => [
            sql_relationship(target_entity => $emp_project_entity,
            join_columns => ['projno'], order_by => 'projno, empno')
        ]
    );

    $entity_manager->add_entities($emp_project_entity, $emp_entity, $project_entity);
}


{
    package Project;
    
    use Abstract::Meta::Class ':all';
    use Persistence::Entity ':all';
    use Persistence::ORM ':all';
    
    entity 'project';
    column projno => has('$.id');
    column name => has('$.name');
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

    many_to_many 'project' => (
        attribute        => has('%.projects' => (associated_class => 'Project'), index_by => 'name'),
        join_entity_name => 'emp_project',
        fetch_method     => LAZY,
        cascade          => ALL,
    );
}

{
    package EagerEmployee;
    
    use Abstract::Meta::Class ':all';
    use Persistence::Entity ':all';
    use Persistence::ORM ':all';
    
    entity 'emp';
    column empno=> has('$.id');
    column ename => has('$.name');
    column job => has '$.job';

    many_to_many 'project' => (
        attribute        => has('%.projects' => (associated_class => 'Project'), index_by => 'name'),
        join_entity_name => 'emp_project',
        fetch_method     => EAGER,
        cascade          => ALL,
    );
}



SKIP: {
    
    ::skip('missing env varaibles DB_TEST_CONNECTION, DB_TEST_USERNAME DB_TEST_PASSWORD', 10)
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
        my ($emp) = $entity_manager->find(emp => 'Employee', name => 'emp2');
        
        ok(! $emp->{'%.projects'}, 'should not have projects - lazy retrieval');
        my $projects = $emp->projects;
        my $exp_result = {
            project3 => Project->new(id => 3, name => 'project3'),
            project1 => Project->new(id => 1, name => 'project1'),
        };
        is_deeply($exp_result, $projects, 'should retrieve projects association');
        
    }
    {
        my ($emp) = $entity_manager->find(emp => 'EagerEmployee', name => 'emp2');
        ok( $emp->{'%.projects'}, 'should have projects - eager retrieval');
    }


    #cascade on insert
    {
        my $emp = Employee->new(name => 'Adrian', job => 'Software Engineer');
        $emp->add_projects(
            Project->new(name => 'Identity'),
            Project->new(name => 'project1')
        );
       $entity_manager->insert($emp);
    }
    
    expected_xml_dataset_ok('insert');
 
    xml_dataset_ok('init');
 
     #cascade on update
    {
        my ($emp) = $entity_manager->find(emp => 'Employee', name => 'emp2');
        $emp->add_projects(
            Project->new(name => 'Identity'),
        );
        $entity_manager->update($emp);
    }
 
    expected_xml_dataset_ok('update');
    
    xml_dataset_ok('init');
     #cascade on delete
    {
        my ($emp) = $entity_manager->find(emp => 'Employee', name => 'emp2');
        $entity_manager->delete($emp);
    }

    expected_xml_dataset_ok('delete');
    
    
}