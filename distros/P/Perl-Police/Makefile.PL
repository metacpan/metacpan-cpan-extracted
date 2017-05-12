use 5.008005;
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name     'Perl-Police';
all_from 'lib/Perl/Police.pm';
author   q{C Hutchinson <taint@cpan.org>};
license  'artistic';

perl_version 5.008005;;

tests_recursive('t');

resources (
   license    => 'http://www.perlfoundation.org/artistic_license_1_0',
   bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Perl-Police',
);

configure_requires (
   'Module::Install' => 0,
);

build_requires (
   'Test::More' => 0.88,
);


install_as_cpan;
auto_install;
WriteAll;
