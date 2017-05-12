use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'SNMP::NPAdmin::Neon',
    'VERSION_FROM'	=> 'Neon.pm',
    'PREREQ_PM'		=> { 'SNMP' => 4.2.0 },
    'DIR'		=> [ 'MIBs' ],
);

#
# $Id: Makefile.PL,v 1.3 2002/11/15 04:04:36 bozzio Exp $
#
