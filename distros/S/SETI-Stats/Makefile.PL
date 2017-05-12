# $Id: Makefile.PL,v 1.7 2001/09/05 09:11:11 martin Exp $

$DISTNAME = 'SETI-Stats';
$VERSION  = "1.06";

use ExtUtils::MakeMaker;

WriteMakefile(
	VERSION   => $VERSION,
#	DISTNAME  => $DISTNAME,
	NAME      => $DISTNAME,
	PMLIBDIRS => [qw(SETI)],
 
	'dist'    => {COMPRESS => 'gzip -9f',
		      SUFFIX   => '.gz', 
		      DIST_DEFAULT => 'all tardist',
		     },
 
	'clean'   => {FILES => join(" ", @clean)},
);

