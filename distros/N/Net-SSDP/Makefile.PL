use strict;
use warnings;
use lib 'ext';
use inc::Module::Install;

name 'Net-SSDP';
license 'lgpl';
all_from 'lib/Net/SSDP.pm';

gssdp or exit;

requires 'Glib';
requires 'parent';

configure_requires 'Glib';
configure_requires 'ExtUtils::Depends';
configure_requires 'ExtUtils::PkgConfig';

test_requires 'Test::More' => '0.89';

no_index directory => 'ext';

WriteAll;
