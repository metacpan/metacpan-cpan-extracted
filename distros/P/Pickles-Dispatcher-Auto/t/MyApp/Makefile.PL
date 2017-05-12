use inc::Module::Install;
name 'MyApp';
all_from 'lib/MyApp.pm';

# requires '';

requires 'Pickles' => 0.10;

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_include;
WriteAll;
