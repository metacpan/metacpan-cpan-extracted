#! /usr/local/bin/perl

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.
WriteMakefile(
	'NAME' => 'String::LRC',
	'DISTNAME' => 'String-LRC',
	'VERSION' => '1.0',
	'OBJECT' => 'LRC.o',
	'dist'   => {COMPRESS=>'gzip', SUFFIX=>'gz'}
);
