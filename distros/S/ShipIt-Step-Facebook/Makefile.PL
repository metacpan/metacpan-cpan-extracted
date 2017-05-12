use inc::Module::Install;
name 'ShipIt-Step-Facebook';
all_from 'lib/ShipIt/Step/Facebook.pm';
readme_from 'lib/ShipIt/Step/Facebook.pm';
readme_markdown_from 'lib/ShipIt/Step/Facebook.pm';
githubmeta;

requires 'YAML';
requires 'LWP::UserAgent';
requires 'HTTP::Request::Common';
requires 'ShipIt';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
auto_set_repository;
WriteAll;
