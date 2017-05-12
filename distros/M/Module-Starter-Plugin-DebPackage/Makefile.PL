use inc::Module::Install;

name     'Module-Starter-Plugin-DebPackage';
all_from 'lib/Module/Starter/Plugin/DebPackage.pm';
author   q{Bradley Dean <bjdean@bjdean.id.au>};
license  'perl';

requires 'Module::Starter::Simple' => 0
       , 'version' => 0;

build_requires 'Test::More' => 0
             , 'Fatal' => 0;

install_script  'bin/debmodule-starter';

auto_install;

WriteAll;

