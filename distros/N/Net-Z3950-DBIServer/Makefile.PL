# $Id: Makefile.PL,v 1.9 2008-05-16 16:46:39 mike Exp $

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME	 => 'Net::Z3950::DBIServer',
    VERSION_FROM => 'lib/Net/Z3950/DBIServer.pm',
    PREREQ_PM    => { 'Net::Z3950::SimpleServer' => 1.03,
		      'DBI' => 1.20,
		      'MARC::Record' => 1.38,
# I don't think these should be prerequisites: see code in DBIServer/XML.pm
#		      'XML::LibXML' => 1.53,
#		      'XML::LibXSLT' => 1.52,
		    },
    AUTHOR       => 'Mike Taylor <mike@miketaylor.org.uk>',
    ABSTRACT     => 'Gateway between Z39.50 and the RDBMS of your choice',
    EXE_FILES    => [ 'bin/zSQLgate', 'bin/zSQLgate-dump-config' ],
    META_ADD => {
	no_index => {
	    namespace => [ 'Net::Z3950::RPN' ],
	},
    },
);

sub MY::postamble { q[
docs:
	cd doc; make

docsclean:
	cd doc; make clean
] }
