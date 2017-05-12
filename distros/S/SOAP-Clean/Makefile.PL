# Copyright (c) 2003, Cornell University
# See the file COPYING for the status of this software

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'SOAP::Clean',
    'VERSION_FROM'	=> 'lib/SOAP/Clean.pm', # finds $VERSION
    'PREREQ_PM'		=> { # e.g., Module::Name => 1.1
			    LWP => 5.65,
			    XML::LibXML => 1.53,
			   },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/SOAP/Clean.pm', # retrieve abstract from module
       AUTHOR     => 'Paul Stodghil <stodghil@cs.cornell.edu>') : ()),
    'LIBS'		=> [''], # e.g., '-lm'
    'EXE_FILES' => [qw(bin/wsdl-client.pl)],
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
	# Insert -I. if you add *.h files later:
    'INC'		=> '', # e.g., '-I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # 'OBJECT'		=> '$(O_FILES)', # link all the C files too
);
