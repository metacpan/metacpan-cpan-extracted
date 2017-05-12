# $Id: Makefile.PL,v 1.2 2005/02/05 14:02:18 roderick Exp $
#
# Copyright (c) 1997 Roderick Schertler.  All rights reserved.  This
# program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME		=> 'Proc::SyncExec',
    VERSION_FROM	=> 'SyncExec.pm',
    dist		=> {
    	COMPRESS 	=> 'gzip --best',
    	DIST_CP		=> 'ln',
    	PREOP		=> '$(MAKE) ci',
    	SUFFIX		=> 'gz',

    	CI		=> 'cvs commit',
	RCS_LABEL	=> 'cvs -q tag -F v$(VERSION_SYM)',
    },
    test		=> { TESTS => '*.t' },
);
