#!/usr/bin/env perl
use 5.006;
use inc::Module::Install;

author		('Autrijus Tang <autrijus@autrijus.org>');
name		('Template-Extract');
abstract	('Use TT2 syntax to extract data from documents');
version_from	('lib/Template/Extract.pm');
license		('perl');

requires	(
    perl	=> 5.006,
    Template	=> 2.00,
);
build_requires	('Test::More');

auto_include_deps();
WriteAll( sign => 1 );
