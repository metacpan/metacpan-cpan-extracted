#! /usr/bin/env perl
use inc::Module::Install;

name 'Test-Apache2';
all_from 'lib/Test/Apache2.pm';
auto_set_repository;

requires 'Class::Accessor::Fast' => 0;
requires 'mod_perl2' => 0;
requires 'IO::Scalar' => 0;

test_requires 'Test::More' => 0;
test_requires 'Test::Pod::Coverage' => 0;

no_index package => 'Apache2::ServerUtil';


WriteAll;
