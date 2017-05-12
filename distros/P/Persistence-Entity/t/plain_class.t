use strict;
use warnings;

use Test::More tests => 9;
use Persistence::Entity::Manager;
use Persistence::Entity ':all';
use Test::DBUnit connection_name => 'test';

my $class;

BEGIN {
    $class = 'Persistence::ORM';
    use_ok($class);
}


my $entity_manager = Persistence::Entity::Manager->new(name => 'my_manager', connection_name => 'test');

$entity_manager->add_entities(
    Persistence::Entity->new(
        name    => 'emp',
        alias   => 'ur',
        primary_key => ['empno'],
        columns => [
            sql_column(name => 'empno'),
            sql_column(name => 'ename', unique => 1),
            sql_column(name => 'job'),
            sql_column(name => 'deptno'),
        ],
    )
);

my $persitence = Persistence::ORM->new(
    mop_attribute_adapter => 'Persistence::Attribute::AMCAdapter',
    entity_name => 'emp',
    class       => 'Employee',
    columns     => {
        empno => {name => 'id'},
        ename => {name => 'name'},
        job   => {name => 'job'},
    }
);
isa_ok($persitence, $class);

    package Employee;

    sub new {
        my $class = shift;
        bless {@_}, $class;
    }


    sub id {
        shift()->{id};
    }

    sub set_id {
        my ($self, $value) = @_;
        $self->{id} = $value;
        $self;
    }

    sub name {
        shift()->{name};
    }

    sub set_name {
        my ($self, $value) = @_;
        $self->{name} = $value;
        $self;
    }

    #or setter/getter in one approach

    sub job {
        my ($self, $value) = @_;
        $self->{job} = $value if (@_ > 1);
        $self->{job};
    }


SKIP: {
    
    ::skip('missing env varaibles DB_TEST_CONNECTION, DB_TEST_USERNAME DB_TEST_PASSWORD', 7)
      unless $ENV{DB_TEST_CONNECTION};

    my $connection = DBIx::Connection->new(
      name     => 'test',
      dsn      => $ENV{DB_TEST_CONNECTION},
      username => $ENV{DB_TEST_USERNAME},
      password => $ENV{DB_TEST_PASSWORD},
    ); 
   
   
    SKIP: {

        my $dbms_name  = $connection->dbms_name;
            ::skip('Tests are not prepared for ' . $dbms_name , 7)
                unless -d "t/sql/". $connection->dbms_name;
   
        # preparing tests
        ::reset_schema_ok("t/sql/". $connection->dbms_name . "/create_schema.sql");
        ::populate_schema_ok("t/sql/". $connection->dbms_name . "/populate_schema.sql");
        ::xml_dataset_ok('t/entity.init.xml');
        {
            my ($emp) = $entity_manager->find(emp => 'Employee', id => 1);
            ::is_deeply($emp, Employee->new(name => 'emp1', id => '1', job => undef), 'should have emp object');
        }
        {
            my $emp = Employee->new(name => 'emp120', id => '120', job => 'manager');
            $entity_manager->insert($emp);
            ::expected_xml_dataset_ok('insert');
        }


        {
            my ($emp) = $entity_manager->find(emp => 'Employee', id => 3);
            $emp->job('Sales Assistant');
            $entity_manager->update($emp);
            ::expected_xml_dataset_ok('update');
        }

        {
            my $emp = Employee->new(name => 'emp2');
            $entity_manager->delete($emp);
            ::expected_xml_dataset_ok('delete');
        }
        
        
        
    }
    
}