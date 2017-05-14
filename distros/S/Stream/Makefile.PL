#! /usr/local/bin/perl

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.
WriteMakefile(
	'NAME' => 'Stream',
	'VERSION' => '1.00',
	'dist'   => {COMPRESS=>'gzip', SUFFIX=>'gz'},
);
