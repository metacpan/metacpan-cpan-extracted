#!/usr/bin/perl

use inc::Module::Install;

name         ('PerlIO-unicodeeol');
author       ('Peter Martini <pcm@cpan.org>');
abstract     ('PerlIO layer for normalizing line endings matching \R to \n');
license      ('perl');
version_from ('unicodeeol.pm');
requires     (perl => '5.7.3');
repository   ('git://github.com/PeterMartini/PerlIO-unicodeeol.git');

WriteAll;
