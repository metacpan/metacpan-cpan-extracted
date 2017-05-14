# $Id: Makefile.PL,v 1.4 1995/11/09 06:38:22 rik Exp $
use ExtUtils::MakeMaker;

WriteMakefile(
	'LIBS' => '-lnsl',
	'INC' => '',
	'DISTNAME' => 'NIS',
	'NAME' => 'Net::NIS',
	'VERSION' => 'a2',
	'PMLIBDIRS' => [ 'NIS' ]
);
