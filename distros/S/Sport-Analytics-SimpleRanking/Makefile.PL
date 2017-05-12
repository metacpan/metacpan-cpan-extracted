use inc::Module::Install;

name     'Sport-Analytics-SimpleRanking';
all_from 'lib/Sport/Analytics/SimpleRanking.pm';
author   q{David Myers <dwm042@email.com>};
license  'perl';

build_requires 'Test::More';
build_requires 'List::Util';
build_requires 'Carp';

auto_install;

WriteAll;

