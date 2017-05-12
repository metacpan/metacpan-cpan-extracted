use strict;
use warnings;

use Test::More tests => 12;
use Test::DBUnit connection_name => 'test';

my $class;

BEGIN {
        $class = 'Persistence::Entity::Manager';
	use_ok($class);
	use_ok('Persistence::Entity', ':all');
        use_ok('Persistence::Entity::Query');
	use_ok('DBIx::Connection');
}


my $entity_manager = $class->new(name => 'myManager', connection_name => 'test');
isa_ok($entity_manager, $class);

$entity_manager->add_entities(Persistence::Entity->new(
    name                  => 'emp',
    unique_expression     => 'empno',
    primary_key           => ['empno'],
    columns               => [
        sql_column(name => 'ename'),
        sql_column(name => 'empno'),
        sql_column(name => 'deptno')
    ],
    indexes => [
	sql_index(name => 'emp_idx1', columns => ['empno'])
    ]
));

	isa_ok($entity_manager->entity('emp'), 'Persistence::Entity');

        package Employee;

        use Abstract::Meta::Class ':all';
        use Persistence::ORM ':all';
        entity 'emp';
        column empno => has('$.no') ;
        column ename => has('$.name');
        column deptno => has('$.deptno');


SKIP: {
    
    ::skip('missing env varaibles DB_TEST_CONNECTION, DB_TEST_USERNAME DB_TEST_PASSWORD', 6)
      unless $ENV{DB_TEST_CONNECTION};

    my $connection = DBIx::Connection->new(
      name     => 'test',
      dsn      => $ENV{DB_TEST_CONNECTION},
      username => $ENV{DB_TEST_USERNAME},
      password => $ENV{DB_TEST_PASSWORD},
    ); 
   
    ::reset_schema_ok("t/sql/". $connection->dbms_name . "/create_schema.sql");
    ::reset_schema_ok("t/sql/". $connection->dbms_name . "/populate_schema.sql");
    
    
    for (1 .. 100) {
        $entity_manager->insert(
            Employee->new(
                no     => $_,
                name   => 'test' . $_,
                deptno => '1'
        ));
    }

    {
	my $query = $entity_manager->query(emp => 'Employee');
	$query->set_offset(20);
	$query->set_limit(5);
	my @emp = $query->execute();
	::is($emp[0]->name,'test20', "have the first query row");
	::is($emp[-1]->name,'test24', "have the last query row");
    }
    
    {
	my $query = $entity_manager->query(emp => undef);
	$query->set_offset(20);
	$query->set_limit(5);
	my @emp = $query->execute();
	::is($emp[0]->{ename},'test20', "have the first query row");
	::is($emp[-1]->{ename},'test24', "have the last query row");
    }
}