# $Id: Makefile.PL 618 2005-12-09 03:24:25Z sungo $

use inc::Module::Install;

name            ('POE-API-Hooks');
author          ('Matt Cashner (sungo@pobox.com)');
version_from    ('VERSION');
license         ('bsd');

requires        ('POE'  => 1.0001);
requires        ('Params::Validate');
requires        ('Test::More');

build_requires  ('Test::Distribution');
build_requires  ('Test::Pod::Coverage');

WriteAll();
