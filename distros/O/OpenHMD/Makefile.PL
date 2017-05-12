#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> 'OpenHMD',
	VERSION_FROM	=> 'lib/OpenHMD.pm',

	PREREQ_PM => {
		'Carp'			=> 0,
		'Const::Fast'	=> 0,
		'Exporter'		=> 0,
		'Inline::C'		=> 0,
	},
	TEST_REQUIRES => {
		'Test::Exception'	=> 0,
		'Test::More'		=> 0,
	},
);
