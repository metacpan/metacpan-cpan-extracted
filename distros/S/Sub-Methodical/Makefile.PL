use inc::Module::Install;

name     'Sub-Methodical';
all_from 'lib/Sub/Methodical.pm';
author   'Hans Dieter Pearcey <hdp@cpan.org>';

build_requires 'Test::More';

requires 'PadWalker';
requires 'Filter::EOF';
requires 'Sub::Exporter';
requires 'Sub::Install';

auto_install;

WriteAll;

