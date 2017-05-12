use inc::Module::Install;

name     'Rule-Engine';
all_from 'lib/Rule/Engine.pm';
author   q{Cory G Watson <gphat@cpan.org>};
license  'perl';

build_requires 'Test::More';

requires 'Moose';

WriteAll;

