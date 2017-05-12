use inc::Module::Install;
name 'Template-Plugin-ResolveLink';
all_from 'lib/Template/Plugin/ResolveLink.pm';

requires 'HTML::ResolveLink';
build_requires 'Test::More';
use_test_base;

auto_include;
WriteAll;
