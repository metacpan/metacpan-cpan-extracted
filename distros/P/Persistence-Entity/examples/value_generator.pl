
use strict;
use warnings;


use DBIx::Connection;
use Persistence::ValueGenerator::TableGenerator ':all';
use Persistence::Entity ':all';
use Persistence::Entity::Manager;

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

package Employee;
use Abstract::Meta::Class ':all';
use Persistence::ORM ':all';

entity 'emp';
column empno=> has('$.id');
column ename => has('$.name');
column job => has '$.job';



my $connection = DBIx::Connection->new(
      name     => 'test',
      dsn      => $ENV{DB_TEST_CONNECTION},
      username => $ENV{DB_TEST_USERNAME},
      password => $ENV{DB_TEST_PASSWORD},
);

$entity_manager->begin_work;
eval {
    my $emp = Employee->new(name => 'Scott');
    $entity_manager->insert($emp);
    $entity_manager->commit;
};

$entity_manager->rollback if $@;

