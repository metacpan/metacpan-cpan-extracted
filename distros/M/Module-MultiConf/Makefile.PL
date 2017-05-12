use inc::Module::Install 0.67;
perl_version '5.008001';
  
name        'Module-MultiConf';
all_from    'lib/Module/MultiConf.pm';

requires    'Config::Any' => 0;
requires    'Params::Validate' => 0;
requires    'Class::Data::Inheritable' => 0;

test_requires  'Test::More' => 0;
test_requires  'Test::Pod' => 0;
test_requires  'Test::Pod::Coverage' => 0;

WriteAll;

