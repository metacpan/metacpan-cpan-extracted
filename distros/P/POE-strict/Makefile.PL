use inc::Module::Install;

name            ('POE-strict');
author          ('Matt Cashner (sungo@pobox.com)');
version_from    ('VERSION');
license         ('bsd');

requires        ('POE');
requires        ('Test::More');

build_requires  ('Test::Distribution');
build_requires  ('Test::Pod::Coverage');

WriteAll();
