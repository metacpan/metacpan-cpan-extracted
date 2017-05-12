use 5.008001;
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name     'Module-Modular';
all_from 'lib/Module/Modular.pm';
author   q{Brad Haywood <brad@perlpowered.com>};
license  'perl';

tests_recursive('t');

resources (
   repository => 'https://github.com/bradhaywood/Module-Modular.git',
   bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Modular',
);

configure_requires (
   'Module::Install' => 0,
);

build_requires (
   'Test::More' => 0,
);

requires (
   'Import::Into',
   #'ABC'              => 1.6,
   #'Foo::Bar::Module' => 5.0401,
);

install_as_cpan;
auto_install;
WriteAll;
