use strict;
use warnings;
use inc::Module::Install;

name('SVG-Convert-Driver-XAML');
author('Toru Yamaguchi <zigorou@cpan.org>');
all_from('lib/SVG/Convert/Driver/XAML.pm');
license('perl');

requires('Carp::Clan');
requires('Getopt::Long');
requires('FindBin');
requires('Path::Class');
requires('Pod::Usage');
requires('SVG::Convert' => 0.02);
requires('XML::LibXML');
requires('XML::LibXSLT');

use_test_base;

auto_include;
auto_install;

WriteAll;
