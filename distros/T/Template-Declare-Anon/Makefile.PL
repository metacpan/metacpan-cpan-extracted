#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'Template::Declare::Anon',
	VERSION_FROM => 'lib/Template/Declare/Anon.pm',
	INSTALLDIRS  => 'site',
	SIGN         => 1,
	PL_FILES     => { },
	PREREQ_PM    => {
		'Template::Declare' => '0.26',
		'Test::use::ok'     => 0,
	},
);

