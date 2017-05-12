use 5.006;
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name     'Net-Saasu';
all_from 'lib/Net/Saasu.pm';
author   q{Lenz Gschwendtner <norbu09@cpan.org>};
license  'artistic2';

perl_version 5.010;

tests_recursive('t');

resources (
   homepage   => 'http://springtimesoft.com/lenz',
   license    => 'http://www.perlfoundation.org/artistic_license_2_0',
   repository => 'git://github.com/norbu09/Net-Saasu.git',
   bugtracker => 'https://github.com/norbu09/Net-Saasu/issues',
);

configure_requires (
   'Module::Install' => 0,
);

build_requires (
   'Test::More' => 0,
);

requires (
    'Any::Moose',
    'LWP::UserAgent',
    'XML::TreePP',
);

install_as_cpan;
auto_install;
WriteAll;
