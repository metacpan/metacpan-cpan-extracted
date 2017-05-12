use inc::Module::Install;
# metadataes
name 'Perlbal-Plugin-Expires';
all_from 'lib/Perlbal/Plugin/Expires.pm';
readme_from 'lib/Perlbal/Plugin/Expires.pm';
# dependencies
requires 'Perlbal';
requires 'HTTP::Date';
# tests
test_requires 'Test::More', 0.96;
tests 't/*.t';
author_tests 'xt';
# misc
auto_include;
WriteAll;
