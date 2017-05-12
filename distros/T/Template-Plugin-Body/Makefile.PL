use inc::Module::Install 0.75;

all_from      'lib/Template/Plugin/Body.pm';
requires      'Template'   => '2.10';
test_requires 'Test::More' => '0.47';

WriteAll;
