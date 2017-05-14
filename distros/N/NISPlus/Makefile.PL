# $Id: Makefile.PL,v 1.8 1997/05/05 21:41:20 rik Exp $
use ExtUtils::MakeMaker;

WriteMakefile(
	'LIBS' => '-lnisdb -lnsl',
	'INC' => '',
	'DISTNAME' => 'NISPlus',
	'NAME' => 'Net::NISPlus',
	'VERSION' => '0.06-alpha',
	'PMLIBDIRS' => [ 'NISPlus' ],
	'dist' => { COMPRESS => 'gzip -9' }
);
