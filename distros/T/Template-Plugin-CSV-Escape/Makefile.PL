use inc::Module::Install;
name 'Template-Plugin-CSV-Escape';
all_from 'lib/Template/Plugin/CSV/Escape.pm';

build_requires 'Test::More';
requires 'Template' => 2.15;
use_test_base;
auto_install;
WriteAll;
