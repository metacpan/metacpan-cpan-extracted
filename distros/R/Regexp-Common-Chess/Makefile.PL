#!/usr/bin/perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile (
	NAME => 'Regexp::Common::Chess',
	AUTHOR => 'Olof Johansson <olof@cpan.org>',
	LICENSE => 'perl',
	ABSTRACT_FROM => 'lib/Regexp/Common/Chess.pm',
	VERSION_FROM => 'lib/Regexp/Common/Chess.pm',
	SIGN => 1,

	PREREQ_PM => {
		'Test::More' => 0,
		'Regexp::Common' => 0,
	},
);

