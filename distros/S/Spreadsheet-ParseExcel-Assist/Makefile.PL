use 5.006;
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name     'Spreadsheet-ParseExcel-Assist';
all_from 'lib/Spreadsheet/ParseExcel/Assist.pm';
author   q{xiangfeng shen <xiangfeng.shen@gmail.com>};
license  'artistic';

perl_version 5.006;

tests_recursive('t');

resources (
   #homepage   => 'http://yourwebsitehere.com',
   #IRC        => 'irc://irc.perl.org/#Spreadsheet-ParseExcel-Assist',
   license    => 'http://www.perlfoundation.org/artistic_license_1_0',
   #repository => 'git://github.com/xiangfeng shen/Spreadsheet-ParseExcel-Assist.git',
   bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Spreadsheet-ParseExcel-Assist',
);

configure_requires (
   'Module::Install' => 0,
);

build_requires (
   'Test::More' => 0,
);

requires (
   #'ABC'              => 1.6,
   #'Foo::Bar::Module' => 5.0401,
);

install_as_cpan;
auto_install;
WriteAll;
