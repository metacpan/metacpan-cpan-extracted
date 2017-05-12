use ExtUtils::MakeMaker;
# $Id: Makefile.PL,v 1.6 2005/03/14 08:49:09 godegisel Exp $
use strict;
require 5.005;

WriteMakefile(
	'NAME'		=> 'POE::Loop::Kqueue',
	'VERSION_FROM'	=> 'Kqueue.pm',
 
	'ABSTRACT_FROM'	=> 'Kqueue.pm',
	'AUTHOR'	=> 'Sergey Skvortsov <skv@protey.ru>',

	'PREREQ_PM'	=> {
    		'POE'	=>	0.3009,
	},

	'CCFLAGS'	=> '-Wall -Wpointer-arith -Winline -Wstrict-prototypes -Wconversion',
#	'DEFINE'	=> '-DLOOP_DEBUG=1',
);
