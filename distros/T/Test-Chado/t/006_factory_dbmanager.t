use Test::More qw/no_plan/;
use Test::Exception;

use_ok('Test::Chado::Factory::DBManager');

dies_ok { Test::Chado::Factory::DBManager->get_instance }
'should die without giving any instance type';
dies_ok { Test::Chado::Factory::DBManager->get_instance('notfound') }
'should die with a non-existing module';
isa_ok( Test::Chado::Factory::DBManager->get_instance('sqlite'),
    'Test::Chado::DBManager::Sqlite' );
isa_ok( Test::Chado::Factory::DBManager->get_instance('pg'),
    'Test::Chado::DBManager::Pg' );
