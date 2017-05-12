#!/usr/bin/env perl

use inc::Module::Install;

name		('Regexp-DefaultFlags');
author		('Damian Conway <dconway@cpan.org>');
abstract	('Set default flags on regular expressions');
license		('perl');
version_from	('lib/Regexp/DefaultFlags.pm');

requires        ( perl => 5.005 );
build_requires  ('Test::More');
auto_include_deps();

WriteAll( sign => 1 );
