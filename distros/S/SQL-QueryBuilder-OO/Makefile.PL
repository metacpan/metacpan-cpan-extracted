#!/usr/bin/perl -w
# $Id: Makefile.PL 44 2015-03-18 14:14:56Z schieche $
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'SQL::QueryBuilder::OO',
	AUTHOR => 'Oliver Schieche <schiecheo@cpan.org>',
	ABSTRACT_FROM => 'lib/SQL/QueryBuilder/OO.pm',
	VERSION_FROM => 'lib/SQL/QueryBuilder/OO.pm',
	MIN_PERL_VERSION => '5.010',
	PREREQ_PM => {
		'Params::Validate' => 0,
		'Date::Parse' => 0
	}
);
