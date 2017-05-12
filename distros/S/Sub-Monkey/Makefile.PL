use inc::Module::Install;

name     'Sub-Monkey';
all_from 'lib/Sub/Monkey.pm';
author   q{Brad Haywood <brad@geeksware.net>};
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

