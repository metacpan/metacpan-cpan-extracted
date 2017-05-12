# $Id: Makefile.PL,v 1.1.1.1 2003/12/18 01:16:49 toni Exp $
#
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'SNMP::Multi',
    'VERSION_FROM'	=> 'Multi.pm', # finds $VERSION
    'PREREQ_PM'		=> {	'SNMP'		=> 4.2,
    				'Memoize'	=> 0.62,
    			   },
);
