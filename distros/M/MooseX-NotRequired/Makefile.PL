use inc::Module::Install;

name     'MooseX-NotRequired';
all_from 'lib/MooseX/NotRequired.pm';
author   q{Colin Newell <colin.newell@gmail.com>};
license  'perl';

build_requires 'Test::Most';
requires 'Moose';

auto_install;

resources(
        'homepage',   => 'https://github.com/colinnewell/MooseX-NotRequired',
        'bugtracker',   => 'https://github.com/colinnewell/MooseX-NotRequired/issues',
        'repository', => 'git://github.com/colinnewell/MooseX-NotRequired.git',
        'license',    => 'http://dev.perl.org/licenses/',
);

WriteAll;

