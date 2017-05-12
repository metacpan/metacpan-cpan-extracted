use strict;
use inc::Module::Install;

name 'Template-Plugin-LinkTo';
all_from 'lib/Template/Plugin/LinkTo.pm';

repository 'http://github.com/hirafoo/Template-Plugin-LinkTo/tree/master';

requires 'Template';
requires 'Template::Plugin';
requires 'Template::Test';
requires 'URI::Escape';
auto_install;

build_requires 'Test::More';
WriteAll;
