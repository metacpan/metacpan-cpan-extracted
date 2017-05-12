use DBIx::Connection;
use Test::More tests => 7;
use Test::DBUnit connection_name => 'test';
use strict;
use warnings;


my $class;

BEGIN {
        $class = 'Persistence::ValueGenerator::TableGenerator';
	use_ok($class, ':all');
	use_ok('Persistence::Entity', ':all');
        use_ok('Persistence::Entity::Manager');
	use_ok('Persistence::Meta::XML');
}


my $meta = Persistence::Meta::XML->new(persistence_dir => 't/value_generator/meta/xml/');


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

	my $entity_manager = $meta->inject('persistence.xml');
	
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