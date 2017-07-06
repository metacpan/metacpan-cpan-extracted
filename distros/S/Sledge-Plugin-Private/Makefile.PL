use inc::Module::Install;
name 'Sledge-Plugin-Private';
all_from 'lib/Sledge/Plugin/Private.pm';

build_requires 'Test::More';
build_requires 'Test::Requires';
requires 'Sledge::Pages::Base' => 0;
author_tests 'xt';
repository 'https://github.com/nipotan/Sledge-Plugin-Private';
WriteAll;
