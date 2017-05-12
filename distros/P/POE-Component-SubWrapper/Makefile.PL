# $Id$
use inc::Module::Install;

name            ('POE-Component-SubWrapper');
author          ('Matt Cashner (sungo@pobox.com)');
version_from    ('VERSION');
license         ('bsd');

requires        ('POE' => 0.23);
requires        ('Devel::Symdump' => 2.01);
requires        ('Exporter::Lite');
requires        ('Test::More' => '0.08');

build_requires  ('Test::Distribution');
build_requires  ('Test::Pod::Coverage');

WriteAll();
