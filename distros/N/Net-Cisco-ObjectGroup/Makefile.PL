use inc::Module::Install 0.67;
perl_version '5.008001';
  
name        'Net-Cisco-ObjectGroup';
all_from    'lib/Net/Cisco/ObjectGroup.pm';

requires    'Class::Accessor' => 0.25;
requires    'Class::Data::Inheritable' => 0;
requires    'UNIVERSAL::require' => 0;

test_requires  'Test::More' => 0;
test_requires  'Test::Pod' => 0;
test_requires  'Test::Pod::Coverage' => 0;

WriteAll;

