use inc::Module::Install;
name 'Module-Install-MicroTemplate';
all_from 'lib/Module/Install/MicroTemplate.pm';

requires 'Module::Install';
requires 'Text::MicroTemplate';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
