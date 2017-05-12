use strict;
use warnings;
use lib 'ext';
use inc::Module::Install;

name 'Pigment';
license 'lgpl';
all_from 'lib/Pigment.pm';

pigment or exit;

requires 'Gtk2';

configure_requires 'Gtk2::CodeGen';
configure_requires 'File::Spec::Functions';
configure_requires 'ExtUtils::Depends';
configure_requires 'ExtUtils::PkgConfig';

no_index directory => qw/ext/;

extra_tests;

WriteAll;
