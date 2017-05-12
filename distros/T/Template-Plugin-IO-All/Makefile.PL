use strict;
use inc::Module::Install;

name            ('Template-Plugin-IO-All');
version_from    ('lib/Template/Plugin/IO/All.pm');
abstract        ('Perl Template Toolkit Plugin for IO::All' );
author          ('Yung-chung Lin <xern@cpan.org>');
license         ('perl');

requires        ('Template');
requires        ('IO::All');
build_requires  ('Test::More');

&WriteAll;

