#!/usr/bin/perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile (
	NAME => 'Parse::M3U::Extended',
	AUTHOR => 'Olof Johansson <olof@cpan.org>',
	LICENSE => 'perl',
	ABSTRACT_FROM => 'lib/Parse/M3U/Extended.pm',
	VERSION_FROM => 'lib/Parse/M3U/Extended.pm',
	SIGN => 1,
	MIN_PERL_VERSION => '5.10.0',

	PREREQ_PM => {
		'JSON' => 0, # build (...test) dependency
	},
);

