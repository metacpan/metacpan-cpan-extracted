use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      'NAME' =>		'SNMP::NPAdmin::MIBs',
	      'VERSION'	=>	'0.1',
	      'PM' =>		{
				 'JETDIRECT3-MIB.txt' =>	'$(INST_LIBDIR)/MIBs/JETDIRECT3-MIB.txt',
				 'Printer-MIB.txt' =>		'$(INST_LIBDIR)/MIBs/Printer-MIB.txt',
				},
	     );

#
# $Id: Makefile.PL,v 1.3 2002/11/15 04:07:09 bozzio Exp $
#
