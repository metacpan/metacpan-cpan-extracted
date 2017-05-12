use inc::Module::Install;
name 'Plagger-Plugin-Notify-Line';
all_from 'lib/Plagger/Plugin/Notify/Line.pm';

build_requires 'Test::More';
build_requires 'Test::Requires';
requires 'Plagger' => 0;
requires 'Furl'    => 0;
author_tests 'xt';
repository 'https://github.com/nipotan/Plagger-Plugin-Notify-Line';
WriteAll;
