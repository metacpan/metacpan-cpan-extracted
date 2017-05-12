#
# Makefile.PL - makemaker script for Statistics::LSNoHistory
#
# $Id: Makefile.PL,v 1.2 2003/02/16 23:48:21 pliam Exp $
#

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'        => 'Statistics::LSNoHistory',
	'VERSION_FROM'    => 'LSNoHistory.pm', # finds $VERSION
	($] >= 5.005 ?    ## Add these new keywords supported since 5.005
		(ABSTRACT_FROM => 'LSNoHistory.pm', # retrieve abstract from module
		AUTHOR     => 'John Pliam <pliam@cpan.org>') : ()),
);
