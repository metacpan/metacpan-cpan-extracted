use v5.10;
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name     'Readonly-Enum';
all_from 'lib/Readonly/Enum.pm';
author   q{Robert Rothenberg <rrwo@cpan.org>};
license  'artistic2';

perl_version 5.010;

tests_recursive('t');

resources (
   license    => 'http://www.perlfoundation.org/artistic_license_2_0',
   repository => 'git://github.com/robrwo/Readonly-Enum.git',
   bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Readonly-Enum',
);

configure_requires (
   'Module::Install' => 0,
);

build_requires (
   'Test::More' => 0,
);

requires (
    'Scalar::Readonly'  => 0,
    'version'		=> 0.77,
);

test_requires ();

install_as_cpan;
auto_install;
WriteAll;
