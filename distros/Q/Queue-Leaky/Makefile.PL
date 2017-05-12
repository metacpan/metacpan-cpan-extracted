use inc::Module::Install;
name 'Queue-Leaky';
all_from 'lib/Queue/Leaky.pm';

requires 'Moose';
requires 'Queue::Base';

build_requires 'Test::More';
auto_include;
WriteAll;
