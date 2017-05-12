#!/usr/bin/perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile (
	NAME => 'Net::SMS::Cellsynt',
	AUTHOR => 'Olof Johansson <zibri@cpan.org>',
	LICENSE => 'perl',
	ABSTRACT_FROM => 'lib/Net/SMS/Cellsynt.pm',
	VERSION_FROM => 'lib/Net/SMS/Cellsynt.pm',

	PREREQ_PM => {
		'WWW::Curl::Easy' => 4.14,
		'URI' => 0,
		'URI::QueryParam' => 0,
		'URI::Escape' => 0,
	},

	SIGN => 1,
);
