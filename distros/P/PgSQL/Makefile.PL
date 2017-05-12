# $Id: Makefile.PL,v 1.3 1998/08/11 20:47:10 goran Exp $

use 5.004;
use ExtUtils::MakeMaker;

#--- Distribution section ---

$DISTNAME = 'PgSQL';

#--- Write the Makefile

WriteMakefile(
	VERSION_FROM   => 'lib/PgSQL.pm',
	DISTNAME  => $DISTNAME,
	NAME      => 'PgSQL',
 
	'dist'    => {COMPRESS => 'gzip -9f',
		      SUFFIX   => '.gz', 
		      DIST_DEFAULT => 'all tardist',
		     },
);



