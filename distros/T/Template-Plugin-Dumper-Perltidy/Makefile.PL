use inc::Module::Install;

name     'Template-Plugin-Dumper-Perltidy';
all_from 'lib/Template/Plugin/Dumper/Perltidy.pm';
author   'Fayland Lam <fayland@gmail.com>';
license  'perl';

requires 'Template';
requires 'Data::Dumper::Perltidy';

build_requires 'Test::More';

auto_install;

WriteAll;

