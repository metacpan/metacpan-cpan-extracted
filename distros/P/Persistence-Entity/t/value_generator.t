use DBIx::Connection;
use Test::More tests => 6;
use Test::DBUnit connection_name => 'test';
use strict;
use warnings;


my $class;

BEGIN {
        $class = 'Persistence::ValueGenerator::TableGenerator';
	use_ok($class, ':all');
	use_ok('Persistence::Entity', ':all');
        use_ok('Persistence::Entity::Manager');
}

my $entity_manager = Persistence::Entity::Manager->new(name => 'my_manager', connection_name => 'test');

table_generator 'empno_generator' => (
    entity_manager_name      => "my_manager",
    table                    => 'seq_generator',
    primary_key_column_name  => 'pk_column',
    primary_key_column_value => 'empno',
    value_column             => 'value_column',
    allocation_size          =>  5,
);


$entity_manager->add_entities(Persistence::Entity->new(
    name                  => 'emp',
    unique_expression     => 'empno',
    primary_key           => ['empno'],
    columns               => [
        sql_column(name => 'ename'),
        sql_column(name => 'empno'),
        sql_column(name => 'deptno')
    ],
    value_generators => {empno => 'empno_generator'},
));

SKIP: {
    skip('missing env varaibles DB_TEST_CONNECTION, DB_TEST_USERNAME DB_TEST_PASSWORD', 3)
      unless $ENV{DB_TEST_CONNECTION};

    my $connection = DBIx::Connection->new(
      name     => 'test',
      dsn      => $ENV{DB_TEST_CONNECTION},
      username => $ENV{DB_TEST_USERNAME},
      password => $ENV{DB_TEST_PASSWORD},
    );

    SKIP: {

        my $dbms_name  = $connection->dbms_name;
            skip('Tests are not prepared for ' . $dbms_name , 3)
                unless -d "t/sql/". $connection->dbms_name;
                
        reset_schema_ok("t/sql/". $connection->dbms_name . "/create_schema.sql");
        xml_dataset_ok('table_generator');
        
        $entity_manager->begin_work;
        my $entity_emp = $entity_manager->entity('emp');
        $entity_emp->insert( ename=> "emp${_}") for (1 .. 12);
        $entity_manager->commit;
        expected_xml_dataset_ok('table_generator');
    }
}