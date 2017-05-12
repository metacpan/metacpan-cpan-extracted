# $Id: Makefile.PL,v 1.1 1997-05-20 22:14:23-04 roderick Exp $
#
# Copyright (c) 1997 Roderick Schertler.  All rights reserved.  This
# program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME		=> 'Proc::WaitStat',
    PREREQ_PM		=> { 'IPC::Signal' => 0 },
    VERSION_FROM	=> 'WaitStat.pm',
    dist		=> {
    	COMPRESS 	=> 'gzip --best',
    	DIST_CP		=> 'ln',
    	PREOP		=> '$(MAKE) ci',
    	SUFFIX		=> 'gz',
    },
);
