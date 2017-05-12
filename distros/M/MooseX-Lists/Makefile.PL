# $Id: Makefile.PL,v 1.3 2010/01/17 09:31:08 dk Exp $
use ExtUtils::MakeMaker;
WriteMakefile(
	NAME          => 'MooseX::Lists',
	AUTHOR        => 'Dmitry Karasik <dmitry@karasik.eu.org>',
	ABSTRACT_FROM => 'lib/MooseX/Lists.pm',
	VERSION_FROM  => 'lib/MooseX/Lists.pm',
	PREREQ_PM     => { 'Moose'  => 0.93 },
);
