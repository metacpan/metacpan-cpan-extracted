use inc::Module::Install;
use 5.010;

name     'Sub-Mage';
all_from 'lib/Sub/Mage.pm';
author   q{Brad Haywood <brad@geeksware.net>};
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

