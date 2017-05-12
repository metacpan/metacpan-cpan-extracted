use inc::Module::Install;
name 'Mojolicious-Plugin-ProxyPassReverse-SubDir';
all_from 'lib/Mojolicious/Plugin/ProxyPassReverse/SubDir.pm';

requires 'Mojolicious' => '4.0';

tests 't/*.t';

test_requires 'Test::More';
auto_set_repository;
auto_include;
auto_manifest;
WriteAll;
