use inc::Module::Install;

name 'Template-Plugin-ArrayRef';
all_from 'lib/Template/Plugin/ArrayRef.pm';

requires 'Template';

auto_install;
auto_set_repository;

WriteAll;
