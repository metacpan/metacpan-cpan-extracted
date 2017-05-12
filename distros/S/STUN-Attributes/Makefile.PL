use inc::Module::Install;

name	'STUN-Status';
author q{Thiago Rondon <thiago@aware.com.br>};
license 'perl';
perl_version '5.10.0';
all_from 'lib/STUN/Attributes.pm';
build_requires 'Test::More';
build_requires 'Test::UseAllModules';

auto_install;

WriteAll;

