use Test::More qw/no_plan/;
use Test::Exception;

use_ok('Test::Chado::Factory::FixtureLoader');
dies_ok { Test::Chado::Factory::FixtureLoader->get_instance }
'should die without giving any instance type';
dies_ok { Test::Chado::Factory::FixtureLoader->get_instance('notfound') }
'should die with a non-existing module';
isa_ok( Test::Chado::Factory::FixtureLoader->get_instance('preset'),
    'Test::Chado::FixtureLoader::Preset' );
isa_ok( Test::Chado::Factory::FixtureLoader->get_instance('flatfile'),
    'Test::Chado::FixtureLoader::Flatfile' );
