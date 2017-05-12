# $Id: Makefile.PL,v 1.2 1998/01/15 10:55:41 ag71333 Exp ag71333 $
#
# Copyright (c) 1998 - 2000 Antonio Rosella Italy
#
# Free usage under the same Perl Licence condition.
#

BEGIN { require 5.005 }

use ExtUtils::MakeMaker 5.16, qw(WriteMakefile $Verbose);
use Config;

if ($] < 5.005) {
	print "\n*** You are using an old version of Perl. ***\n\a";
	print "Perl 5.005 fixes many bugs in older versions and is highly recommended.\n";
	sleep 5;
}

%opts = (
	NAME=> 'PDF',
	VERSION_FROM=> 'PDF.pm',
	clean => { FILES=> '$(DISTVNAME)/' },
	dist  => {
		DIST_DEFAULT=> 'clean distcheck disttest ci tardist',
		PREOP => '$(MAKE) -f Makefile.old distdir',
		COMPRESS => 'gzip -v9', SUFFIX => 'gz',
	},
);

$Verbose = 1;
WriteMakefile( %opts );

# end.
