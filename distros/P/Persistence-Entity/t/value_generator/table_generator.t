use strict;
use warnings;

use Test::More tests => 19;
use Test::DBUnit connection_name => 'my_connection';

my $class;

BEGIN {
    $class = "Persistence::ValueGenerator::TableGenerator";
    use_ok($class);
    use_ok('Persistence::Entity::Manager');
}




my $entity_manager = Persistence::Entity::Manager->new(name => 'my_manager', connection_name => 'my_connection');
my $allocation_size = 3;
my $generator = $class->new(
    entity_manager_name      => "my_manager",
    name                     => 'pk_generator',
    table                    => 'seq_generator',
    schema                   => '',
    primary_key_column_name  => 'pk_column',
    primary_key_column_value => 'empno',
    value_column             => 'value_column',
    allocation_size          =>  $allocation_size,
);


SKIP: {
    
    skip('missing env varaibles DB_TEST_CONNECTION, DB_TEST_USERNAME DB_TEST_PASSWORD', 17)
      unless $ENV{DB_TEST_CONNECTION};

    my $connection = DBIx::Connection->new(
      name     => 'my_connection',
      dsn      => $ENV{DB_TEST_CONNECTION},
      username => $ENV{DB_TEST_USERNAME},
      password => $ENV{DB_TEST_PASSWORD},
    );

    $entity_manager->begin_work;
    
    $connection->do("DELETE FROM seq_generator");
    isa_ok($generator, $class);
    for my $i (0 .. 7) {
        ::is(!! $generator->has_cached_seq, !! ($i  % $allocation_size), ("should access database (alloc size: $allocation_size): " . (! ($i  % $allocation_size) ? 'yes' : 'no')));
        ::is($generator->nextval, $i + 1, "should have " .($i + 1) . " seq");
    }
    $entity_manager->commit;
    
}