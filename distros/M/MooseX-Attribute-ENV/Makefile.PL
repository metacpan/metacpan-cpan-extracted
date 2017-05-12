use inc::Module::Install 0.75;

perl_version '5.008006';
name     'MooseX-Attribute-ENV';
all_from 'lib/MooseX/Attribute/ENV.pm';
author   'John Napiorkowski <jjnapiork@cpan.org>';

requires 'Moose' => '0.48';

build_requires 'Test::More';

auto_install;

WriteAll;

