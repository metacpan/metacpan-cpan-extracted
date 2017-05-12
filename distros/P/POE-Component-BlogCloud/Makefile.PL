# $Id: Makefile.PL 1783 2005-01-09 05:44:52Z btrott $

use inc::Module::Install;

name('POE-Component-BlogCloud');
abstract('Client for blo.gs streaming cloud server');
author('Benjamin Trott <ben+cpan@stupidfool.org>');
version_from('lib/POE/Component/BlogCloud.pm');
license('perl');
no_index(directory => 't');
sign(1);

include('ExtUtils::AutoInstall');

requires('POE');
requires('XML::SAX');
requires('DateTime');
requires('Class::Accessor');

auto_include();
auto_install();

&WriteAll;
