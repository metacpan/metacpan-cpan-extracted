
use strict;
use warnings;

use Test::More tests => 36;

my $class;

BEGIN {
    $class = "Persistence::ValueGenerator::SequenceGenerator";
    use_ok($class, ':all');
    use_ok('Persistence::Entity::Manager');
}


# before run ensure that you have that table
#CREATE TABLE seq_generator(pk_column VARCHAR(30), value_column bigint)

my $entity_manager = Persistence::Entity::Manager->new(name => 'my_manager', connection_name => 'my_connection');

SKIP: {
    
    skip('missing env varaibles DB_TEST_CONNECTION, DB_TEST_USERNAME DB_TEST_PASSWORD', 34)
      unless $ENV{DB_TEST_CONNECTION};

    my $connection = DBIx::Connection->new(
      name     => 'my_connection',
      dsn      => $ENV{DB_TEST_CONNECTION},
      username => $ENV{DB_TEST_USERNAME},
      password => $ENV{DB_TEST_PASSWORD},
    );
    
   skip("mysql doesn't support sequences", 34)
	if (lc($connection->dbms_name) eq 'mysql');
    {
        my $allocation_size = 1;
        my $generator = $class->new(
            entity_manager_name  => 'my_manager',
            name                 => 'pk_generator',
            sequence_name        => 'emp_seq',
            allocation_size      =>  $allocation_size,
        );
        
        $entity_manager->begin_work;
        $connection->reset_sequence(lc($connection->dbms_name) eq 'mysql' ? 'emp' : "emp_seq",  1, 1);

        isa_ok($generator, $class);
        for my $i (0 .. 7) {
            ::is(!! $generator->has_cached_seq, !! ($i  % $allocation_size), ("should access database (alloc size: $allocation_size): " . (! ($i  % $allocation_size) ? 'yes' : 'no')));
            ::is($generator->nextval, $i + 1, "should have " .($i + 1) . " seq");
        }
        $entity_manager->commit;
    }
    
    {
        my $allocation_size = 3;
        my $generator = sequence_generator 'pk_generator' => (
            entity_manager_name  => 'my_manager',
            sequence_name        => 'emp_seq',
            allocation_size      =>  $allocation_size,
        )   ;
        
        $entity_manager->begin_work;
        $connection->reset_sequence("emp_seq", 1, 3);
        isa_ok($generator, $class);
        for my $i (0 .. 7) {
            ::is(!! $generator->has_cached_seq, !! ($i  % $allocation_size), ("should access database (alloc size: $allocation_size): " . (! ($i  % $allocation_size) ? 'yes' : 'no')));
            ::is($generator->nextval, $i + 1, "should have " .($i + 1) . " seq");
        }
        $entity_manager->commit;
    }
}

# CREATE SEQUENCE emp_seq START 1;

