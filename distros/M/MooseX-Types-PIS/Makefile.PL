use inc::Module::Install;

name     'MooseX-Types-PIS';
all_from 'lib/MooseX/Types/PIS.pm';
author   q{Breno G. de Oliveira <garu@cpan.org>};
license  'perl';

build_requires 'Test::More';

requires 'MooseX::Types';
requires 'Business::BR::PIS';

auto_install;

WriteAll;

