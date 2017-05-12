###

###
# File:		Makefile.PL
# Author:	Janos Mohacsi, mohacsi@ik.bme.hu
# Orignal Traceroute.pm Author:	Daniel Hagerty, hag@ai.mit.edu
# Date:		Fri Aug 31 11:00:04 CEST 2001	
# Description:	perl style Makefile for this Traceroute6.pm
#

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME	  => 'Net::Traceroute6',
	VERSION_FROM => "Traceroute6.pm",

	'dist'    => {COMPRESS => 'gzip -9f',
		      SUFFIX   => '.gz',
		      DIST_DEFAULT => 'all tardist',
		     },
);
