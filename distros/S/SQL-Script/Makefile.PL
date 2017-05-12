use inc::Module::Install 0.91;

all_from      'lib/SQL/Script.pm';
requires      'Carp';
requires      'Params::Util' => '0.10';
test_requires 'Test::More'   => '0.47';
test_requires 'File::Spec'   => '0.80';

WriteAll;
