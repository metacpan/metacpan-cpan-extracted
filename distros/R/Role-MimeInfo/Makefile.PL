use 5.012;
use strict;
use warnings;
use inc::Module::Install;

name        'Role-MimeInfo';
readme_from 'lib/Role/MimeInfo.pm';
all_from    'lib/Role/MimeInfo.pm';
author      q{Dorian Taylor <dorian@cpan.org>};
license     'apache';

perl_version 5.012;

tests_recursive('t');

resources (
   homepage   => 'https://github.com/doriantaylor/p5-role-mimeinfo',
   license    => 'http://www.apache.org/licenses/LICENSE-2.0',
   repository => 'git://github.com/doriantaylor/p5-role-mimeinfo.git',
   bugtracker => 'https://github.com/doriantaylor/p5-role-mimeinfo/issues',
);

configure_requires (
   'Module::Install' => 0,
);

build_requires (
   'Test::More' => 0,
);

requires (
    'Moo'                  => '2.003',
    'namespace::autoclean' => '0.28',
    'File::MimeInfo'       => '0.27',
    'IO::Scalar'           => '2.110',
);

install_as_cpan;
auto_install;
WriteAll;
