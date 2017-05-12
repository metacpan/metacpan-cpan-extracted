use inc::Module::Install;

name	'STUN-Client';
author q{Thiago Rondon <thiago@aware.com.br>};
license 'perl';
all_from 'lib/STUN/Client.pm';
build_requires 'Test::More';
build_requires 'Test::UseAllModules';

requires 'Moose';
requires 'Moose::Util::TypeConstraints';
requires 'Socket';
requires 'String::Random';
requires 'STUN::RFC_5389';

requires 'Test::More';
requires 'Test::Exception';
requires 'Data::Validate::IP';

auto_install;

WriteAll;

