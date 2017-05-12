#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'MooseX::Role::TraitConstructor',
	VERSION_FROM => 'lib/MooseX/Role/TraitConstructor.pm',
	INSTALLDIRS  => 'site',
	SIGN         => 1,
	PL_FILES     => { },
	PREREQ_PM    => {
		'Test::use::ok' => 0,
        'Test::Exception' => 0,
        'Moose' => '0.40',
        'List::Util' => 0,
	},
);

