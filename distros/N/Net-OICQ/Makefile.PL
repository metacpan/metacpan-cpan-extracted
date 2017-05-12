use ExtUtils::MakeMaker;

# $Id: Makefile.PL,v 1.10 2007/06/16 13:58:03 tans Exp $

# Copyright (c) 2002, 2003 Shufeng Tan.  All rights reserved.
# 
# This package is free software and is provided "as is" without express
# or implied warranty.  It may be used, redistributed and/or modified
# under the terms of the Perl Artistic License (see
# http://www.perl.com/perl/misc/Artistic.html)

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'		=> 'Net::OICQ',
    'VERSION_FROM'	=> 'lib/Net/OICQ.pm', # finds $VERSION
    'PREREQ_PM'		=> {Crypt::OICQ     => 1.0,
                            Digest::MD5     => 0.1,
		            IO::Select      => 0.1,
                            Term::ANSIColor => 0.1,
		    	    Term::ReadKey   => 0,
		    	},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Net/OICQ.pm', # retrieve abstract from module
       AUTHOR     => 'Shufeng Tan <shufengtan@gmail.com>') : ()),
    'LIBS'		=> [''],
    'EXE_FILES'		=> ['bin/qq'],
    'DEFINE'		=> '',
    'INC'		=> '-I.',
);
