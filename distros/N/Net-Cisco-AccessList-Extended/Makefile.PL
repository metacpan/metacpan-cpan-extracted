use inc::Module::Install 0.67;
perl_version '5.008001';
  
name        'Net-Cisco-AccessList-Extended';
all_from    'lib/Net/Cisco/AccessList/Extended.pm';

requires    'Class::Accessor' => 0;
requires    'List::MoreUtils' => 0;

test_requires  'Test::More' => 0;
test_requires  'Test::Pod' => 0;
test_requires  'Test::Pod::Coverage' => 0;

WriteAll;

