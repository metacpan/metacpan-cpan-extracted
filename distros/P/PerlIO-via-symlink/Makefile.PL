#!/usr/bin/perl
use inc::Module::Install;

name		('PerlIO-via-symlink');
author		('Chia-liang Kao <clkao@clkao.org>');
abstract	('PerlIO layer for symlinks');
license		('perl');
version_from	('symlink.pm');
clean_files	('symlink-test'); # from test

include('ExtUtils::AutoInstall');
auto_install();

WriteAll( sign => 1 );
