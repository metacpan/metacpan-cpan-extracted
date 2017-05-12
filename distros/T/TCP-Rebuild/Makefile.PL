use 5.006;
use strict;
use warnings;

use inc::Module::Install;

name          ('TCP-Rebuild');
author        ('David Cannings <david@edeca.net>');
license       ('perl');
all_from      ('lib/TCP/Rebuild.pm');

requires('Net::LibNIDS'	=> '0.04'); # bugfixes
requires('Pod::Usage'	=> '1.00');

#extra_tests;

install_script('bin/tcprebuild');

repository('http://github.com/edeca/TCP-Rebuild');

WriteAll();
