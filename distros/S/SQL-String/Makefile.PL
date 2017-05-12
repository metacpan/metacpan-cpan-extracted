use inc::Module::Install 0.75;

all_from      'lib/SQL/String.pm';
requires      'Carp'       => 0;
test_requires 'Test::More' => '0.47';

WriteAll;
