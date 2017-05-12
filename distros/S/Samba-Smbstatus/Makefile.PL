use 5.006;
use strict;
use warnings FATAL => 'all';
use inc::Module::Install 0.78;;

name     'Samba-Smbstatus';
all_from 'lib/Samba/Smbstatus.pm';
author   q{Louis Erickson <laufeyjarson@laufeyjarson.com>};
license  'artistic2';

perl_version 5.006;

tests_recursive('t');

resources (
   homepage   => 'http://blog.laufeyjarson.com',
   #IRC        => 'irc://irc.perl.org/#Samba-Smbstatus',
   license    => 'http://www.perlfoundation.org/artistic_license_2_0',
   repository => 'https://github.com/laufeyjarson/samba-smbstatus.git',
   bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Samba-Smbstatus',
);

configure_requires (
   'Module::Install' => 0,
);

build_requires (
   'Test::More' => 0,
);

requires (
   'Moo' => 0,
);

requires_external_bin 'smbstatus';

install_as_cpan;
auto_install;

WriteAll;
