use strict;
use warnings;
use inc::Module::Install;

name 'PDL-FuncND';

license 'gpl3';
author 'Diab Jerius';

all_from 'lib/PDL/FuncND.pm';

requires 'PDL';

test_requires 'Test::More';
test_requires 'Test::Trap';

tests_recursive;

repository 'http://bitbucket.org/djerius/pdl-funcnd';
bugtracker 'https://rt.cpan.org/Public/Dist/Display.html?Name=PDL-FuncND';

author_tests('xt');
author_requires 'Test::CPAN::Changes';
auto_install;

WriteAll;
