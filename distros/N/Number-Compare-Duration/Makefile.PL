use inc::Module::Install;

name     'Number-Compare-Duration';
all_from 'lib/Number/Compare/Duration.pm';
author   'Hans Dieter Pearcey <hdp@cpan.org>';

build_requires 'Test::More';

requires 'Number::Compare';

auto_manifest;
extra_tests;
WriteAll;

