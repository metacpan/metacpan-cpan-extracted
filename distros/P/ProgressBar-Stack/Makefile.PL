#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'ProgressBar::Stack',
	VERSION_FROM => 'lib/ProgressBar/Stack.pm',
	INSTALLDIRS  => 'site',
	PREREQ_PM    => {
		'Time::HiRes' => 0,
		'List::Util' => 0,
		'Test::More' => 0,
	},
    AUTHOR => 'Tagir Valeev <lan@nprog.ru>',
    ABSTRACT_FROM => 'lib/ProgressBar/Stack.pm',
);

