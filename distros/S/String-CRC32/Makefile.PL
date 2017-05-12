#! /usr/local/bin/perl

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.
WriteMakefile(
	'NAME' => 'String::CRC32',
	'DISTNAME' => 'String-CRC32',
	'VERSION' => '1.5',
	'OBJECT' => 'CRC32.o',
	'dist'   => {COMPRESS=>'gzip', SUFFIX=>'gz'}
);
