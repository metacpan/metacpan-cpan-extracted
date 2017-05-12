# $Id: Makefile.PL 626 2005-12-11 19:53:32Z sungo $
use inc::Module::Install;

name         ('POE-Component-RSS');
author       ('Matt Cashner (sungo@pobox.com)');
version_from ('VERSION');
license      ('bsd');

requires ('POE');
requires ('XML::RSS');
requires ('Test::More');
requires ('Params::Validate');

build_requires  ('Test::Distribution');
build_requires  ('Test::Pod::Coverage');

WriteAll();

