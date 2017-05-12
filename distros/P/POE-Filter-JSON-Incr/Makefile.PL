#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'POE::Filter::JSON::Incr',
	VERSION_FROM => 'lib/POE/Filter/JSON/Incr.pm',
	INSTALLDIRS  => 'site',
	SIGN         => 1,
	PL_FILES     => { },
	PREREQ_PM    => {
		'Test::use::ok' => 0,
		'JSON' => '2.12', # incr api with bugfixes
		'Any::Moose' => '0',
		'POE::Filter' => 0,
		'namespace::clean' => '0.08',
	},
);

