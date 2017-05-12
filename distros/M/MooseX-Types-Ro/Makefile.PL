#!perl
use strict;
use warnings;
use inc::Module::Install 0.92;

name 'MooseX-Types-Ro';
author "Dagfinn Ilmari Manns\x{a9}ker <ilmari\@ilmari.org>";
all_from 'lib/MooseX/Types/Ro.pm';
readme_from 'lib/MooseX/Types/Ro.pm' => 'clean';
readme_pod_from 'lib/MooseX/Types/Ro.pm';
githubmeta;

requires 'Internals'     => '1.1';
requires 'MooseX::Types' => '0';
requires 'namespace::autoclean' => '0';

test_requires 'Test::More' => '0.88';

author_requires 'Test::Pod' => '0';
author_tests 't/author';

WriteAll;
