use strict;
use warnings;

use Test::More tests => 9;
use Test::DBUnit connection_name => 'test';
use Persistence::Meta::XML;

{
    package Employee;
    use Abstract::Meta::Class ':all';
    
    has '$.id';
    has '$.name';
    has '$.job';
    has '$.dept_name';
    has '$.dept' => (associated_class => 'Department');
}


{
    package Department;
    use Abstract::Meta::Class ':all';
    
    has '$.id';
    has '$.name';
    has '$.location';
    has '@.employees' => (associated_class => 'Employee');
    
}

my $meta = Persistence::Meta::XML->new(
    persistence_dir => 't/relationship/meta/',
);

my $entity_manager = $meta->inject('persistence.xml');
isa_ok($entity_manager, 'Persistence::Entity::Manager');

SKIP: {
    
    ::skip('missing env varaibles DB_TEST_CONNECTION, DB_TEST_USERNAME DB_TEST_PASSWORD', 8)
      unless $ENV{DB_TEST_CONNECTION};

    my $connection = DBIx::Connection->new(
      name     => 'test',
      dsn      => $ENV{DB_TEST_CONNECTION},
      username => $ENV{DB_TEST_USERNAME},
      password => $ENV{DB_TEST_PASSWORD},
    ); 


    xml_dataset_ok('init');
    {
        my ($dept) = $entity_manager->find(dept => 'Department', name => 'dept3');
        my @employees = $dept->employees;
        is_deeply(\@employees, [
            Employee->new(id => 1, name => 'emp1', job => undef, dept_name => 'dept3', dept => $dept),
            Employee->new(id => 4, name => 'emp4', job => undef, dept_name => 'dept3', dept => $dept),
            ], 'should have employees');
        is_deeply($dept, $employees[0]->dept(), 'should have dept');
    
        my ($employee) = $entity_manager->find(emp => 'Employee', name => 'emp4');
        is_deeply($employee, $employees[-1], 'should have employee');
    }
 
    {   
        my $enp = Employee->new(id => 88, name => 'emp88');
        $enp->set_dept(Department->new(id => 99, name => 'd99'));
        $entity_manager->insert($enp);
        expected_xml_dataset_ok('insert');
    }
 
    {
        my ($dept) = $entity_manager->find(dept => 'Department', name => 'dept3');
        my @employees = $dept->employees;
        $dept->set_name('l');
        $dept->remove_employees($employees[-1]);
        $entity_manager->update($dept);
        expected_xml_dataset_ok('update');
    }
    
    {
        xml_dataset_ok('init');
        my ($dept) = $entity_manager->find(dept => 'Department', name => 'dept3');
        $entity_manager->delete($dept);
        expected_xml_dataset_ok('delete');
    }
    
}